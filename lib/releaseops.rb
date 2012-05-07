require 'rake'
require 'rake/tasklib'

module ReleaseOps
  # require some libaray we provide
  def self.require_libs(*libs)
    libs.each do |lib|
      require File.expand_path(File.join('..', 'releaseops', lib), __FILE__)
    end
  end

  # @option opts [String] :prefix ('releaseops') a string to prepend to the
  #   directory name generated under Dir.tmpdir
  #
  # @option opts [true,false] :autoclean (true) if true, we remove the directory
  #   if false, we only remove the directory if there was no exception
  #
  def self.with_tmpdir(opts={})
    require 'tmpdir'
    prefix = opts.fetch(:prefix, 'releaseops')

    dir = File.join(Dir.tmpdir, "#{prefix}.#{rand(1_000_000)}_#{$$}_#{Time.now.strftime('%Y%m%d%H%M%S')}")

    $stderr.puts "Using tmpdir: #{dir}"

    FileUtils.mkdir_p(dir)

    yield(dir).tap do
      FileUtils.rm_rf(dir) unless opts[:autoclean]
    end
  ensure
    FileUtils.rm_rf(dir) if opts[:autoclean]
  end
end

ReleaseOps.require_libs('yard_tasks', 'test_tasks', 'simplecov')

