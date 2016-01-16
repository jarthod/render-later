# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
require File.expand_path("../../test/dummy/config/environment.rb",  __FILE__)

ActiveSupport::TestCase.test_order = :random if ActiveSupport::TestCase.respond_to? :test_order=
require 'minitest/autorun'
