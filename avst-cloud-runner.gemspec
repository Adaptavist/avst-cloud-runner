# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'avst-cloud-runner/version'

Gem::Specification.new do |spec|
    spec.name          = "avst-cloud-runner"
    spec.version       = AvstCloudRunner::VERSION
    spec.authors       = ["Martin Brehovsky", "Jon Bevan", "Matthew Hope"]
    spec.email         = ["mbrehovsky@adaptavist.com", "jbevan@adaptavist.com", "mhope@adaptavist.com"]
    spec.summary       = %q{Runner for avst-cloud gem }
    spec.description   = %q{Enables avst-cloud functionality and params parsing}
    spec.homepage      = "http://www.adaptavist.com"

    spec.files         = `git ls-files -z`.split("\x0")
    spec.executables   = ["avst-cloud-runner"]
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ["lib"]
    spec.required_ruby_version = '~> 2.4.0'
    spec.add_development_dependency "bundler", "~> 1.6"
    spec.add_development_dependency "rake"
    spec.add_dependency "avst-cloud", ">= 0.1.41"
    ##spec.add_dependency "azure"
    spec.add_dependency "hiera_loader", ">= 0.0.2"
    spec.add_dependency "hiera-eyaml"
    spec.add_dependency "confluence_reporter", "~> 0.0.5"
    spec.add_dependency "derelict"
    spec.add_dependency "docopt", ">= 0.5.0"
    spec.add_dependency "rainbow"
end

