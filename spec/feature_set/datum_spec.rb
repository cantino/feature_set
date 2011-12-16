require 'spec_helper'

describe FeatureSet::Datum do
  describe "tokenize" do
    it "should return an array of tokens" do
      FeatureSet::Datum.new("hello world sup?").tokens.should =~ ["hello", "world", "sup"]
    end

    it "should memoize" do
      datum = FeatureSet::Datum.new("hello world sup?")
      datum.tokens.should =~ ["hello", "world", "sup"]
      datum.value = "hello"
      datum.tokens.should =~ ["hello", "world", "sup"]
    end
  end

  describe "#token_counts" do
    it "should provide counts for each token" do
      datum = FeatureSet::Datum.new("hello world sup?  hello!")
      datum.token_counts.should == { "hello" => 2, "world" => 1, "sup" => 1}
    end

    it "should memoize" do
      datum = FeatureSet::Datum.new("hello world sup?  hello!")
      datum.token_counts.should == { "hello" => 2, "world" => 1, "sup" => 1}
      datum.value = "hello"
      datum.instance_variable_set(:@tokens, ["hello"])
      datum.token_counts.should == { "hello" => 2, "world" => 1, "sup" => 1}
    end
  end
end