require 'spec_helper'

describe FeatureSet::FeatureBuilders::WordVector do
  it "should output a named feature for every word in the dataset, after performing tfidf" do
    builder = FeatureSet::FeatureBuilders::WordVector.new
    dataset = [
                { :m1 => "hello world.  hello!", :m2 => "how goes?", :class => :yes }, 
                { :m1 => "foo world", :m2 => "how?", :class => :no }
              ]
    wrapped_dataset = FeatureSet::DataSet.wrap_dataset(dataset)
    builder.before_build_features(wrapped_dataset)

    builder.idfs.should == {
                             :m1 => { "hello" => Math.log(2/1.0), "world" => Math.log(2/2.0), "foo" => Math.log(2/1.0) },
                             :m2 => { "how" => Math.log(2/2.0), "goes" => Math.log(2/1.0) }
                           }

    builder.build_features(wrapped_dataset.first[:m1], :m1, wrapped_dataset.first).should == { "wv_hello" => (2/3.0) * Math.log(2/1.0), "wv_world" => (1/3.0) * Math.log(2/2.0), "wv_foo" => 0 }
    builder.build_features(wrapped_dataset.first[:m2], :m2, wrapped_dataset.first).should == { "wv_how" => (1/2.0) * Math.log(2/2.0), "wv_goes" => (1/2.0) * Math.log(2/1.0) }

    builder.build_features(wrapped_dataset.last[:m1], :m1, wrapped_dataset.last).should == { "wv_hello" => 0, "wv_world" => (1/2.0) * Math.log(2/2.0), "wv_foo" => (1/2.0) * Math.log(2/1.0) }
    builder.build_features(wrapped_dataset.last[:m2], :m2, wrapped_dataset.last).should == { "wv_how" => (1/1.0) * Math.log(2/2.0), "wv_goes" => 0 }
  end

  it "should ignore non-string features" do
    builder = FeatureSet::FeatureBuilders::WordVector.new
    builder.before_build_features([{ :something => FeatureSet::Datum.new(2), :class => false }, { :something => FeatureSet::Datum.new(1), :class => true }])
    builder.build_features(FeatureSet::Datum.new(2), :something, { :something => FeatureSet::Datum.new(2), :class => false }).should == {}
  end
  
  it "should allow specifying the idf cutoff" do
    builder = FeatureSet::FeatureBuilders::WordVector.new(:idf_cutoff => 2.0)
    dataset = [{ :m1 => "hello world.  hello!", :class => true }] * 10
    dataset <<  { :m1 => "foo", :class => false }
    wrapped_dataset = FeatureSet::DataSet.wrap_dataset(dataset)
    builder.before_build_features(wrapped_dataset)
    builder.idfs.should == {
                             :m1 => { "hello" => Math.log(11/10.0), "world" => Math.log(11/10.0) }
                           }
  end
  
  it "should allow specifying an word-count threshold" do
    builder = FeatureSet::FeatureBuilders::WordVector.new(:word_limit => 2)
    dataset = [{ :m1 => "hello world.  hello!", :class => true }] * 10
    dataset <<  { :m1 => "foo", :class => false }
    dataset <<  { :m1 => "hello", :class => false }
    dataset <<  { :m1 => "hello", :class => false }
    wrapped_dataset = FeatureSet::DataSet.wrap_dataset(dataset)
    builder.before_build_features(wrapped_dataset)
    builder.idfs.should == {
                             :m1 => { "hello" => Math.log(13/12.0), "world" => Math.log(13/10.0) }
                           }

    builder = FeatureSet::FeatureBuilders::WordVector.new(:word_limit => 1)
    dataset = [{ :m1 => "hello world.  hello!", :class => true }] * 10
    dataset <<  { :m1 => "foo", :class => false }
    dataset <<  { :m1 => "world", :class => false }
    dataset <<  { :m1 => "world", :class => false }
    wrapped_dataset = FeatureSet::DataSet.wrap_dataset(dataset)
    builder.before_build_features(wrapped_dataset)
    builder.idfs.should == {
                             :m1 => { "world" => Math.log(13/12.0) }
                           }
  end
end
