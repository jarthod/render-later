require 'test_helper'
require './app/helpers/render_later/view_helper.rb'

class RenderLater::HelperTest < ActionView::TestCase
  include RenderLater::ViewHelper
  attr_accessor :request

  def setup
    @request = Object.new
    # @chunks = []
  end

  # def concat data
  #   @chunks << data
  # end

  def test_render_later_store_block_and_render_invisible_span
    assert_empty send(:deferred_objects)
    res = render_later("key") { assert false }
    assert_dom_equal res, '<span id="rl-key" class="rl-placeholder" style="display: none"></span>'
    refute_empty send(:deferred_objects)
  end

  def test_render_later_does_not_accept_duplicate_key
    render_later("key") { assert false }
    ex = assert_raises RenderLater::Error do
      render_later("key") { assert false }
    end
    assert_equal ex.message, "duplicate key: key"
  end

  def test_render_now_outputs_blocks_in_javascript
    render_later("key") { 42 }
    assert_nil render_now
  end

  def test_gem_has_a_version_number
    refute_nil ::RenderLater::VERSION
  end
end
