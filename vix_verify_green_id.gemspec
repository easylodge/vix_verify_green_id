lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vix_verify_green_id/version"

Gem::Specification.new do |spec|
  spec.name          = "vix_verify_green_id"
  spec.version       = VixVerifyGreenId::VERSION
  spec.authors       = ["MonsieurSlim", "Jean le Roux"]
  spec.email         = ["luccy559slim@gmail.com", "support@easylodge.com.au"]

  spec.summary       = %q{Vix Verify's Green ID Identity Verification.}
  spec.description   = %q{Rails gem for using Vix Verify's Green ID Identity Verification service.}
  spec.homepage      = "https://github.com/easylodge/vix_verify_green_id"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency 'rails', '~> 4.0.0'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'shoulda-matchers', '~>2.8'
  spec.add_development_dependency 'pry'

  spec.add_dependency "nokogiri"
  spec.add_dependency "httparty"
  spec.add_dependency 'activesupport'
end
