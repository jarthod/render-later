require "render-later/version"
require "render-later/engine" if defined?(::Rails)

module RenderLater
  class Error < StandardError; end
end
