# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'systemd_alert/version'

Gem::Specification.new do |spec|
  spec.name          = "systemd_alert"
  spec.version       = SystemdAlert::VERSION
  spec.authors       = ["Jon Cairns"]
  spec.email         = ["jon@joncairns.com"]
  spec.summary       = %q{Provides an API to run callbacks when systemd services enter into a failed state.}
  spec.description   = %q{Provides an API to run callbacks when systemd services enter into a failed state.}
  spec.homepage      = "https://github.com/joonty/systemd_alert"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-dbus"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
