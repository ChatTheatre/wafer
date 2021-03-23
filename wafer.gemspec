require_relative 'lib/wafer/version'

Gem::Specification.new do |spec|
  spec.name          = "wafer"
  spec.version       = Wafer::VERSION
  spec.authors       = ["Noah Gibbs"]
  spec.email         = ["the.codefolio.guy@gmail.com"]

  spec.summary       = %q{Wafer is a development-only auth server for SkotOS games.}
  spec.description   = %q{Wafer is a development-only AuthD/CtlD and web server for developing your SkotOS-based games. For a production-quality auth server, please use thin-auth instead.}
  spec.homepage      = "http://github.com/noahgibbs/wafer"
  spec.license       = "AGPL"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
