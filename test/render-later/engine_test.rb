require 'test_helper'
require 'capybara/dsl'
require 'capybara/poltergeist'
Capybara.app = Rails.application
Capybara.server = :puma, { Silent: true }
Capybara.default_driver = :poltergeist

class RenderLater::EngineTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  def test_engine_is_loaded
    assert_equal ::Rails::Engine, RenderLater::Engine.superclass
  end

  def test_helpers_works
    visit "/?sleep=0"
    assert page.has_content?("srv-10"), "srv-10 not found"
    assert page.has_css?('li .uptime', text: "UP · 99.9%"), "later block not rendered"
    assert page.has_no_css?('span.rl-placeholder', visible: false), "placeholder still present"
  end

  def test_streaming_works
    Net::HTTP.start(Capybara.current_session.server.host, Capybara.current_session.server.port) do |http|
      start = Time.now
      chunks = []
      request = Net::HTTP::Get.new "/?sleep=0.2"
      http.request request do |response|
        response.read_body do |chunk|
          chunks << Time.now - start
        end
      end
      assert_operator chunks.size, :>, 10, "Not enough streaming chunks"
      assert_operator chunks.last - chunks.first, :>, 1, "Not enough time between first and last chunk"
    end
  end

  def test_order_preservation
    visit "/order_test"
    assert page.has_no_css?('span.rl-placeholder', visible: false), "placeholder still present"
    assert_equal "012345678", page.find('#order_test').text
  end

end
