module ReleaseOps
  module YardTasks
    extend ::Rake::DSL if defined?(::Rake::DSL)

    # defines yard-relates tasks under the 'yard' namespace
    #
    # @option opts [String,Symbol] :namespace (:yard) what namespace should we
    #   define our taks in?
    # @option opts [Integer] :port (8808) what port to serve documentation on
    # @option opts [Integer] :gem_port (8809) what port to serve this project's
    #   gem documentation on
    #
    def self.define(opts={})
      port      = opts[:port]
      gem_port  = opts.fetch(:gem_port, 8809)
      ns        = opts.fetch(:namespace, :yard)

      namespace ns do
        task :clean do
          rm_rf '.yardoc'
        end

        task :server => :clean do
          cmd = ["yard server --reload"]
          cmd << "--port=#{port}" if port 
          sh(*cmd)
        end

        task :gems do
          cmd = ["yard server --reload"]
          cmd << "--port=#{gem_port}" if gem_port 
          sh(*cmd)
        end
      end
    end
  end
end
