require 'spec_helper'

describe FeatureSet::FeatureBuilder::Emoticon do
  before do
    @builder = FeatureSet::FeatureBuilder::Emoticon.new
  end

  it "should output counts of the number of distinct emoticons of each type" do
    @builder.generate_features(FeatureSet::Datum.new("blah :) XP"), nil, nil).should == { :happy_emoticon_count => 1, :humor_emoticon_count => 1, :sad_emoticon_count => 0 }
    @builder.generate_features(FeatureSet::Datum.new("blah ;) :("), nil, nil).should == { :happy_emoticon_count => 0, :humor_emoticon_count => 1, :sad_emoticon_count => 1 }
  end

  it "should ignore non-string features" do
    @builder.generate_features(FeatureSet::Datum.new(2), nil, nil).should == {}
  end
end
