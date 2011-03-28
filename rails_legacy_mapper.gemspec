# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rails_legacy_mapper/version"

Gem::Specification.new do |s|
  s.name        = "rails_legacy_mapper"
  s.version     = RailsLegacyMapper::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Andrew White"]
  s.email       = ["andyw@pixeltrix.co.uk"]
  s.homepage    = %q{https://github.com/pixeltrix/rails_legacy_mapper/}
  s.summary     = %q{Old style routes for Rails 3.1}
  s.description = <<-EOF
This gem provides an extraction of the DeprecatedMapper from Rails 3.0.
If you have a legacy application with an old style routes.rb file this
allows you to get your application running quickly in Rails 3.1.
EOF

  s.files = [
    ".gemtest",
    "CHANGELOG",
    "LICENSE",
    "README",
    "Rakefile",
    "lib/rails_legacy_mapper.rb",
    "lib/rails_legacy_mapper/mapper.rb",
    "lib/rails_legacy_mapper/route_set_extensions.rb",
    "lib/rails_legacy_mapper/version.rb",
    "rails_legacy_mapper.gemspec",
    "test/fake_controllers.rb",
    "test/legacy_route_set_test.rb",
    "test/rack_mount_integration_test.rb",
    "test/resources_test.rb",
    "test/route_set_test.rb",
    "test/test_helper.rb",
    "test/uri_reserved_characters_routing_test.rb"
  ]

  s.test_files    = [
    "test/fake_controllers.rb",
    "test/legacy_route_set_test.rb",
    "test/rack_mount_integration_test.rb",
    "test/resources_test.rb",
    "test/route_set_test.rb",
    "test/test_helper.rb",
    "test/uri_reserved_characters_routing_test.rb"
  ]

  s.require_paths = ["lib"]

  s.add_dependency "rails", "~> 3.1.0.beta"
  s.add_development_dependency "bundler", "~> 1.0.10"
  s.add_development_dependency "mocha", "~> 0.9.8"
  s.add_development_dependency "rake", "~> 0.8.7"
end
