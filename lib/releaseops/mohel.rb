module ReleaseOps
  require_libs(*%w[ mohel/git_utils ])

  # http://en.wikipedia.org/wiki/Mohel
  #
  # the mohel cuts our gems
  module Mohel
    class MohelError < StandardError; end

    class BuildTask < ::Rake::TaskLib
      include GitUtils

      # the gemspec we're going to build. defaults to the first gemspec found in the 
      # same directory as the Rakefile
      attr_accessor :gemspec_name

      # where the gem will be saved to
      attr_writer :package_dir
      
      # set environment that should be inherited specifically in phase two
      # which is the clean-room phase of the build
      attr_reader :phase_two_env

      attr_accessor :tag
  
      def initialize(namespace=:mohel)
        @namespace = namespace
        @gemspec_name = Dir['*.gemspec'].sort.first
        @phase_two_env = {}

        yield self if block_given?

        # only used in phase one, phase two is run from *inside* this dir
        @temp_dir_path = File.join(Dir.tmpdir, "#{@gemspec_name}_#{$$}_#{Time.now.utc.strftime('%Y%m%d%H%M%S')}")

        define
      end

      private
        def phase_two?
          ENV['PHASE'] == '2'
        end

        def tag
          ENV['TAG'] || raise "You must set TAG in the environment"
        end
        
        # the PACKAGE_DIR env var will be set in subordinate rake invocations
        # in the primary rake process this value will created by this method
        def package_dir
          @package_dir ||= ENV.fetch('PACKAGE_DIR') { File.join(Dir.getwd, 'pkg') }
        end

        # runs the actual gem creation task in the "clean room" directory (phase 2)
        def run_gem_package_task
          sh "rvm 1.8.7 do gem build #{@gemspec_name}"
          cp FileList["*.gem"], package_dir

        end

        def trace?
          Rake.application.options.trace
        end
  
        # preps the clean room build and execs the second phase of the build (phase 1)
        def do_clean_room_build_of_gem_at_tag
          raise "tag #{tag} does not exist!" unless git_tag.include?(tag)

          $stderr.puts "cloning repo at tag '#{tag}' to #{@temp_dir_path}"
          git_archive_tag(tag, @temp_dir_path)
          $stderr.puts "running phase two"

          cmd = "rake #{trace? and '-t '}#{@namespace}:phase_two_gem['#{tag}']"

          env = phase_two_env.merge('PHASE' => 2, 'PACKAGE_DIR' => package_dir, 'TAG' => tag)

          unless system(env, cmd, :chdir => @temp_dir_path)
            raise "system(#{env.inspect}, #{cmd.inspect}, :chdir => #{@temp_dir_path.inspect}) failed" 
          end
        end

        def define
          raise "Couldn't find a gemspec and none specified" unless @gemspec_name
          raise "Specified gemspec doesn't exist" unless File.exists?(@gemspec_name)

          directory package_dir

          namespace(@namespace) do
            task :do_git_fetch do
              git_fetch unless ENV['SKIP_GIT_FETCH']
            end

            # this is a hook you can hang pre-gem-packaging tasks off of
            task :before_gem_package

            # this will only run if we've done the whole "clean-room" thing and
            # invoked rake as a subtask
            if phase_two?
              task :phase_two_gem => :before_gem_package do |t,args|
                $stderr.puts "[DEBUG] phase_two_gem args: #{args.inspect}"
                run_gem_package_task 
              end
            end

            task :build_gem => [:do_git_fetch, package_dir] do |t,args|
              self.tag = args.tag if args.tag
              do_clean_room_build_of_gem_at_tag
              rm_rf @temp_dir_path
            end

#             desc %Q[
#               |create a gem. if argument :tag is specified, then use that as the tag and
#               |use the basename of the tag name as the gem version. If :tag is
#               |not given, build the gem for the latest tag in the repo. Then 
#               |push the created gem up to our rubygems repository.
#             ].margin

#             task :publish_gem, [:tag] => :build_gem do |t,args|
#               self.tag = args.tag if args.tag
#               sh "gem push "
#             end
          end
        end
    end
  end
end


