require 'test_helper'
require 'capybara/dsl'
require 'capybara/poltergeist'
Capybara.app = Rails.application
Capybara.default_driver = :poltergeist

class RenderLater::EngineTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  def test_engine_is_loaded
    assert_equal ::Rails::Engine, RenderLater::Engine.superclass
  end

  def test_helpers_works
    visit "/"
    assert page.has_content?("srv-10"), "srv-10 not found"
    assert page.has_css?('li .uptime', text: "UP · 99.9%"), "later block not rendered"
    assert page.has_no_css?('span.rl-placeholder', visible: false), "placeholder still present"
  end

  def test_order_preservation
    visit "/order_test"
    assert page.has_no_css?('span.rl-placeholder', visible: false), "placeholder still present"
    assert_equal "012345678", page.find('#order_test').text
  end

end
