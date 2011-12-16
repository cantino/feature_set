require 'spec_helper'

describe FeatureSet::FeatureBuilder::Cuss do
  it "should output :cuss_count as the number of distinct cuss words found" do
    builder = FeatureSet::FeatureBuilder::Cuss.new
    builder.generate_features(FeatureSet::Datum.new("this fucking shit"), nil, nil).should == { :cuss_count => 2 }
    builder.generate_features(FeatureSet::Datum.new("this fucking fucking fucking shit"), nil, nil).should == { :cuss_count => 2 }
  end
end