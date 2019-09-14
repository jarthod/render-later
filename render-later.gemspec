# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'render-later/version'

Gem::Specification.new do |spec|
  spec.name          = "render-later"
  spec.version       = RenderLater::VERSION
  spec.authors       = ["Adrien Jarthon"]
  spec.email         = ["me@adrienjarthon.com"]

  spec.summary       = %q{Defer rendering of slow parts to the end of the page}
  spec.description   = %q{Render-later allows you to defer the rendering of slow parts of your views to the end of the page, allowing you to drastically improve the time to first paint and perceived performance.}
  spec.homepage      = "https://github.com/jarthod/render-later"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rails", ">= 5.1"
  spec.add_development_dependency "puma"
  spec.add_development_dependency "poltergeist"
end
