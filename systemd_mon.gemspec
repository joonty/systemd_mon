# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'systemd_mon/version'

Gem::Specification.new do |spec|
  spec.name          = "systemd_mon"
  spec.version       = SystemdMon::VERSION
  spec.authors       = ["Jon Cairns"]
  spec.email         = ["jon@joncairns.com"]
  spec.summary       = %q{Monitor systemd units and trigger alerts for failed states}
  spec.description   = %q{Monitor systemd units and trigger alerts for failed states}
  spec.homepage      = "https://github.com/joonty/systemd_mon"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-dbus", "~> 0.16.0"
  spec.add_dependency "slack-notifier", "> 1.0"
  spec.add_dependency "mail", "> 2.0"
  spec.add_dependency "hipchat", "> 1.5"
  spec.add_dependency "dingbot", "> 0.2"
  spec.add_dependency "gelf", "> 3.0"
  spec.add_development_dependency "bundler", ">= 1.6"
  spec.add_development_dependency "rake"
end
