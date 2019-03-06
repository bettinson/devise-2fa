require 'bundler/setup'
require 'rotp'
require "dummy/application"
Bundler.setup

Dummy::Application.initialize!

RSpec.configure do |config|
  # some (optional) config here
end
