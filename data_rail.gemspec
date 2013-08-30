# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'data_rail/version'

Gem::Specification.new do |spec|
  spec.name          = "data_rail"
  spec.version       = DataRail::VERSION
  spec.authors       = ["Venkat Dinavahi"]
  spec.email         = ["venkat@letsfunnel.com"]
  spec.description   = %q{DataRail provides a record importer and compound operations for operations like booking.}
  spec.summary       = %q{DataRail provides a set of tools that makes importing and computing data a breeze.}
  spec.homepage      = "http://www.letsfunnel.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "virtus"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.required_ruby_version = '>= 2.0'
end
