require 'rake'
require 'rake/tasklib'

module ReleaseOps
  # require some libaray we provide
  def self.require_libs(*libs)
    libs.each do |lib|
      require File.expand_path(File.join('..', 'releaseops', lib), __FILE__)
    end
  end

  def self.gem_files
    FileList['*zookeeper-*.gem']
  end
end

ReleaseOps.require_libs('yard_tasks', 'test_tasks', 'simplecov')

