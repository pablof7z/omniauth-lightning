# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omniauth-lightning/version"

Gem::Specification.new do |s|
  s.name        = "omniauth-lightning"
  s.version     = OmniAuth::Lightning::VERSION
  s.authors     = ["Pablo Fernandez"]
  s.email       = ["pfer@me.com"]
  s.homepage    = "https://github.com/heelhook/omniauth-lightning"
  s.description = %q{OmniAuth strategy for Lightning Network}
  s.summary     = s.description
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.3')
  s.add_dependency 'omniauth-oauth', '~> 1.1'
  s.add_dependency 'rest-client', '~> 2'
  s.add_dependency 'rack'
  # s.add_development_dependency 'bundler', '~> 2.1'
end
