# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
require File.expand_path("../../test/dummy/config/environment.rb",  __FILE__)

ActiveSupport::TestCase.test_order = :random
require 'minitest/autorun'
