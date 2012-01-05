require 'spec_helper'

describe FeatureSet::FeatureBuilders::Cuss do
  before do
    @builder = FeatureSet::FeatureBuilders::Cuss.new
  end

  it "should output :cuss_count as the number of distinct cuss words found" do
    @builder.build_features(FeatureSet::Datum.new("this fucking shit"), nil, nil).should == { :cuss_count => 2 }
    @builder.build_features(FeatureSet::Datum.new("this fucking fucking fucking shit"), nil, nil).should == { :cuss_count => 2 }
  end

  it "should ignore non-string features" do
    @builder.build_features(FeatureSet::Datum.new(2), nil, nil).should == {}
  end
end
