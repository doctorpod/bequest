# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bequest/version'

Gem::Specification.new do |s|
  s.name          = "bequest"
  s.version       = Bequest::VERSION
  s.authors       = ["Andy White"]
  s.email         = ["andy@wireworldmedia.co.uk"]
  s.description   = %q{License secure data}
  s.summary       = %q{Bequest enables password, MAC address and expiry-based validation and secure data provision via a single license file.}
  s.homepage      = ""
  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.add_runtime_dependency "macaddr", ">= 1.6.1"
  s.add_development_dependency "rspec", ">= 0"
end
