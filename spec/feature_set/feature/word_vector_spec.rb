require 'spec_helper'

describe FeatureSet::FeatureBuilder::WordVector do
  it "should output a named feature for every word in the dataset, after performing tfidf" do
    builder = FeatureSet::FeatureBuilder::WordVector.new
    dataset = [
                { :m1 => "hello world.  hello!", :m2 => "how goes?", :class => :yes }, 
                { :m1 => "foo world", :m2 => "how?", :class => :no }
              ]
    wrapped_dataset = FeatureSet::Builder.wrap_dataset(dataset)
    builder.before_generate_features(wrapped_dataset)

    builder.idfs.should == {
                             :m1 => { "hello" => Math.log(2/1.0), "world" => Math.log(2/2.0), "foo" => Math.log(2/1.0) },
                             :m2 => { "how" => Math.log(2/2.0), "goes" => Math.log(2/1.0) }
                           }

    builder.generate_features(wrapped_dataset.first[:m1], :m1, wrapped_dataset.first).should == { "wv_hello" => (2/3.0) * Math.log(2/1.0), "wv_world" => (1/3.0) * Math.log(2/2.0), "wv_foo" => 0 }
    builder.generate_features(wrapped_dataset.first[:m2], :m2, wrapped_dataset.first).should == { "wv_how" => (1/2.0) * Math.log(2/2.0), "wv_goes" => (1/2.0) * Math.log(2/1.0) }

    builder.generate_features(wrapped_dataset.last[:m1], :m1, wrapped_dataset.last).should == { "wv_hello" => 0, "wv_world" => (1/2.0) * Math.log(2/2.0), "wv_foo" => (1/2.0) * Math.log(2/1.0) }
    builder.generate_features(wrapped_dataset.last[:m2], :m2, wrapped_dataset.last).should == { "wv_how" => (1/1.0) * Math.log(2/2.0), "wv_goes" => 0 }
  end

  it "should ignore non-string features" do
    builder = FeatureSet::FeatureBuilder::WordVector.new
    builder.before_generate_features([{ :something => FeatureSet::Datum.new(2), :class => false }, { :something => FeatureSet::Datum.new(1), :class => true }])
    builder.generate_features(FeatureSet::Datum.new(2), :something, { :something => FeatureSet::Datum.new(2), :class => false }).should == {}
  end
end
