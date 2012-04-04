# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "feature_set/version"

Gem::Specification.new do |s|
  s.name        = "feature_set"
  s.version     = FeatureSet::VERSION
  s.authors     = ["Andrew Cantino"]
  s.email       = ["andrew@iterationlabs.com"]
  s.homepage    = "https://github.com/iterationlabs/feature_set"
  s.summary     = %q{Generate feature vectors from textual data}
  s.description = %q{FeatureSet is a Ruby library for generating feature vectors from textual data.  It can output in ARFF format for experimentation with Weka.}

  s.rubyforge_project = "feature_set"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "iterationlabs-rarff"
end
