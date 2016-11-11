$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "doorkeeper-couchbase/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "doorkeeper-couchbase"
  s.version     = DoorkeeperCouchbase::VERSION
  s.authors     = ["Stephen von Takach"]
  s.email       = ["steve@aca.im"]
  s.homepage    = "http://github.com/acaprojects/doorkeeper-couchbase"
  s.summary     = "Doorkeeper Couchbase ORMs"
  s.description = "Doorkeeper Couchbase ORMs"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "doorkeeper", ">= 3.0.0"

  s.add_development_dependency "sqlite3", "~> 1.3.5"
  s.add_development_dependency "rspec-rails", "~> 3.4.0"
  s.add_development_dependency "capybara", "~> 2.3.0"
  s.add_development_dependency "generator_spec", "~> 0.9.0"
  s.add_development_dependency "factory_girl", "~> 4.5.0"
  s.add_development_dependency "timecop", "~> 0.7.0"
  s.add_development_dependency "database_cleaner", "~> 1.5.0"
end
