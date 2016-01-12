$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'action_view'
require 'render-later'
require './app/helpers/render-later/helper.rb'
require 'minitest/autorun'

ActiveSupport::TestCase.test_order = :random