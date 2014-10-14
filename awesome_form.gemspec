# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "awesome_form/version"

Gem::Specification.new do |spec|
  spec.name          = "awesome_form"
  spec.version       = AwesomeForm::VERSION
  spec.authors       = ["Nathan Wallace"]
  spec.email         = ["nathan@nosuchthingastwo.com"]
  spec.summary       = %q{Easily wrap your models in form objects to keep business logic where it belongs.}
  spec.description   = %q{Provides a DSL for creating form objects that wrap model classes.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "pry"

  spec.add_runtime_dependency "activemodel", ">= 3.0.0"
end
