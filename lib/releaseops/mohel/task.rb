module ReleaseOps
module Mohel
  # for use with the MB::GemManager pattern in config/versions.rb
  class GemDepCollector
    attr_reader :gems

    def initialize
      @gems = []
    end

    def gem(name, opts={})
      @gems << [name, opts]
    end
  end

  class Task < ::Rake::TaskLib
    include GitUtils
    CONFIG_VERSIONS_PATH = 'config/versions.rb'

    attr_reader :gem_spec

    # for internal use and testing
    attr_accessor :tag #:nodoc:

    # set environment that should be inherited specifically in phase two
    attr_reader :phase_two_env

    RDOC_DEFAULT_OPTS = %w[--inline-source --charset=UTF-8].freeze

    def initialize(spec=nil, namespace=:mohel)
      @phase_two_env    = {}
      @gem_spec         = GemSpecWrapper.new(spec)

      if File.exist?(CONFIG_VERSIONS_PATH)
        add_gem_deps_from_config_version_rb(CONFIG_VERSIONS_PATH)
      end

      yield self if block_given?

      if @gem_spec.files.nil? || @gem_spec.files.empty?
        @gem_spec.files = FileList["[A-Z]*.*", "{bin,generators,lib,test,spec}/**/*"]
      end

      if @gem_spec.has_rdoc.nil?    # if still at its default value
        @gem_spec.has_rdoc = true
      end

      @mohel        = Mohel::Bandage.new(@gem_spec)
      @release_mgr  = Mohel::ReleaseManager.new
      @namespace    = namespace

      unless phase_two?
        @tag ||= @release_mgr.refresh.latest_release_tag
      end

      # only used in phase one, phase two is run from *inside* this dir
      @temp_dir_path = File.join(Dir.tmpdir, "#{@gem_spec.name}_#{$$}_#{Time.now.utc.strftime('%Y%m%d%H%M%S')}")

      define
    end

    protected
      def phase_two?
        ENV['PHASE'] == '2'
      end

      def trace?
        Rake.application.options.trace
      end

      # gem version is the basename of tag
      def gem_version
        File.basename(tag) if tag
      end

      # the PACKAGE_DIR env var will be set in subordinate rake invocations
      # in the primary rake process this value will created by this method
      def package_dir
        @package_dir ||= ENV.fetch('PACKAGE_DIR') { File.join(Dir.getwd, 'pkg') }
      end

      # stolen mostly from rake-0.8.3/lib/rake/gempackagetask.rb and turned into a ternary operation
#       def gem_file_name
#         @gem_file_name ||= (gem_spec.platform == Gem::Platform::RUBY) ? "#{gem_spec.name}-#{gem_version}.gem" : "#{gem_spec.name}-#{gem_version}-#{gem_spec.platform}.gem"
#       end

      # preps the clean room build and execs the second phase of the build (phase 1)
      def do_clean_room_build_of_gem_at_tag
        raise "tag #{tag} does not exist!" unless git_tag.include?(tag)

        $stderr.puts "cloning repo at tag '#{tag}' to #{@temp_dir_path}"
        git_archive_tag(tag, @temp_dir_path)
        $stderr.puts "running phase two"
        phase_two_env_args = phase_two_env.sort.map { |k,v| "#{k}='#{v}'" }.join(' ')
        sh "cd #{@temp_dir_path} && rake #{trace? and '-t '}#{@namespace}:phase_two_gem['#{tag}'] PHASE=2 PACKAGE_DIR=#{package_dir} #{phase_two_env_args}"
      end

      # runs the actual gem creation task in the "clean room" directory (phase 2)
      def run_gem_package_task
        require 'rake/gempackagetask'

        # we set this late in the game
        #
        # NOTE: this is done on *purpose* to prevent people from accidentally
        # setting the version in the gem spec
        gem_spec.really_set_the_version_to(gem_version)

        t = Rake::GemPackageTask.new(gem_spec.wrapped_obj) do |t|
          t.package_dir = package_dir
          t.need_zip = t.need_tar = false
        end

        Rake::Task[:gem].invoke
      end

      SNIP_TASK_DESC = %q<
      |The meta-task of mohel. This task will cut a new release of the
      |gem (using the mohel:cut:* tasks), build the gem, and then upload
      |it to the motionbox rubygems server and update the indexes.
      |
      |Parameters:
      |
      |  release: The symbolic name 'major', 'minor', or 'patch', signifying
      |           that we're bumping the revision number, or 'latest' to 
      |           indicate we're building the gem for the latest tag of the
      |           repo
      |
      |  ref: When given and a tag is to be cut, used as the git reference that
      |       we are going to tag. If not specified, HEAD will be used by default.
      |
      |examples of usage:
      |
      | # assume the gem we're packaging is called 'fancypants' and the
      | # current latest tag is 3.7.8
      | 
      | # to tag HEAD as relesae/4.0.0, build fancypants-4.0.0.gem, and deploy it
      |
      |   $ rake mohel:snip[major]
      |
      | # to tag HEAD as release/3.8.0, build fancypants-3.8.0.gem, and deploy it
      |
      |   $ rake mohel:snip[minor]
      |
      | # to tag branch dev/your-fly-is-down as release/3.7.9, 
      | # build fancypants-3.7.9.gem, and deploy it (note the single quotes
      | # around the name of the task, this is because of the space between
      | # the two parameters):
      |
      |   $ rake 'mohel:snip[patch, dev/your-fly-is-down]'
      |
      | # to build and deploy the latest tag
      |
      |   $ rake mohel:snip[latest]
      |
      >.margin

      def handle_tag_task_argument(args)
      end

      def add_gem_deps_from_config_version_rb(module_path)
        load(module_path)
        gm = Object.const_get(:MB).const_get(:GemManager)

        gdc = GemDepCollector.new
        gm.configure_gems(gdc)
        
        gdc.gems.each do |name, opts|
          @gem_spec.add_dependency(*[name, opts[:version]].compact)
        end
      rescue NameError => e
        raise MohelError, "No MB::GemManager module defined at path #{module_path.inspect} (caught #{e.class}: #{e})", caller
      rescue NoMethodError => e
        if e.to_s =~ /undefined method `configure_gems'/
          raise MohelError, "MB::GemManager.configure_gems not defined", caller
        else
          raise e
        end
      end

      def define
        namespace(@namespace) do
          task :do_git_fetch do
            git_fetch unless ENV['SKIP_GIT_FETCH']
          end

          # this is a hook you can hang pre-gem-packaging tasks off of
          task :before_gem_package

          # this will only run if we've done the whole "clean-room" thing and
          # invoked rake as a subtask
          if phase_two?
            task :phase_two_gem, [:tag] => :before_gem_package do |t,args|
              $stderr.puts "[DEBUG] phase_two_gem args: #{args.inspect}"
              ENV['TAG'] = self.tag = args.tag if args.tag
              run_gem_package_task 
            end
          end

          task :build_gem, [:tag] => :do_git_fetch do |t,args|
            self.tag = args.tag if args.tag
            do_clean_room_build_of_gem_at_tag
            rm_rf @temp_dir_path
          end

          desc %Q[
            |create a gem. if argument :tag is specified, then use that as the tag and
            |use the basename of the tag name as the gem version. If :tag is
            |not given, build the gem for the latest tag in the repo. Then 
            |push the created gem up to our rubygems repository.
          ].margin

          task :publish_gem, [:tag] => :build_gem do |t,args|
            self.tag = args.tag if args.tag
            publish_gem_with_vlad
          end

          namespace :cut do
            ReleaseManager::VALID_RELEASE_TYPES.each do |rtype|
              desc "create and publish a #{rtype} release tag of the current head"
              task rtype => '^do_git_fetch' do
                @release_mgr.tag_release!(rtype)
                @tag = @release_mgr.refresh.latest_release_tag
              end
            end
          end

#           desc(SNIP_TASK_DESC)
#           task :snip, [:release,:branch] do |t,args|
#             $stderr.puts "I'm terribly sorry, this task is not yet implemented"
#             exit 1
#           end
        end
      end
  end
end
end # ReleaseOps
