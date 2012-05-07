require 'rake'
require 'rake/tasklib'
require 'fileutils'
require 'pathname'
require 'rubygems'

module ReleaseOps
  # require some libaray we provide
  def self.require_libs(*libs)
    libs.each do |lib|
      require File.expand_path(File.join('..', 'releaseops', lib), __FILE__)
    end
  end
end

ReleaseOps.require_libs('core_ext', 'yard_tasks', 'test_tasks', 'simplecov', 'mohel')


