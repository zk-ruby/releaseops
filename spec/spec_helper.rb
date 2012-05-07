require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, :test)

Dir[File.expand_path('../support/**/*.rb', __FILE__)].sort.each { |f| require(f) }

RSpec.configure do |config|
  config.mock_with :rspec
end

