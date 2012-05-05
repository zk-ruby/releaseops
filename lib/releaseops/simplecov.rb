module ReleaseOps
  module SimpleCov
    def self.enabled?
      ENV['RELEASEOPS_COVERAGE'] && (RUBY_VERSION =~ /\A1\.9/)
    end

    # Starts simplecov if enabled?
    #
    # yields to the block if given inside the SimpleCov.start block
    # for config
    #
    def self.maybe_start
      return unless enabled?
      require 'rubygems'
      require 'bundler/setup'
      require 'simplecov'

      ::SimpleCov.start do
        add_filter do |source_file|
          source_file.filename =~ %r%((?:\b|/)spec/|/logging.rb\Z)%
        end

        yield if block_given?
      end
    end
  end
end

