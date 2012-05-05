require 'rake'
require 'rake/tasklib'

module ReleaseOps
  # require some libaray we provide
  def self.require_libs(*libs)
    deps.each do |dep|
      require File.expand_path(File.join('..', 'releaseops', dep), __FILE__)
    end
  end
end

ReleaseOps.require_libs('yard_tasks', 'test_tasks', 'simplecov')

