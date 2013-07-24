$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "reversable_tiny_url/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "reversable_tiny_url"
  s.version     = ReversableTinyUrl::VERSION
  s.authors     = ["Matt Edlefsen"]
  s.email       = ["matt@xforty.com"]
  s.homepage    = "http://www.snapmylife.com"
  s.summary     = "Provides a reversable tiny url for snapmylife"
  s.description = "Provides a reversable tiny url for snapmylife"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "> 2.3.0"
end
