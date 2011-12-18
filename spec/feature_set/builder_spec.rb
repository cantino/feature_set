require 'spec_helper'

describe FeatureSet::Builder do
  describe "adding feature builders" do
    it "can add all known feature builders" do
      builder = FeatureSet::Builder.new
      builder.add_feature_builders :all
      builder.feature_builders.map {|i| i.class}.should include(FeatureSet::FeatureBuilder::WordVector)
      builder.feature_builders.length.should == Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "feature_set", "feature_builder", "*.rb"))].length - 1
    end
    
    it "can add individual feature builders" do
      builder = FeatureSet::Builder.new
      builder.add_feature_builder FeatureSet::FeatureBuilder::WordVector.new
      builder.feature_builders.length.should == 1
    end

    it "can add arrays of feature builders" do
      builder = FeatureSet::Builder.new
      builder.add_feature_builders [FeatureSet::FeatureBuilder::WordVector.new, FeatureSet::FeatureBuilder::Cuss.new]
      builder.feature_builders.length.should == 2
    end
  end
  
  describe "adding data" do
    it "should accept mappings between one or more strings and their classifications" do
      builder = FeatureSet::Builder.new
      builder.add_data [ { :status => "I am happy!", :class => :happy },
                         { :status => "I am sad." , :class => :sad } ]
      builder.data.should == [ { :status => "I am happy!", :class => :happy },
                               { :status => "I am sad." , :class => :sad } ]
      builder.add_data :status => "Something", :another_feature => "Something else", :class => :awesome
      builder.data.should == [ { :status => "I am happy!", :class => :happy },
                               { :status => "I am sad." , :class => :sad },
                               { :status => "Something", :another_feature => "Something else", :class => :awesome } ]
      builder.clear_data
      builder.data.should == []
      builder.data = [ { :status => "I am happy!", :class => :happy },
                       { :status => "I am sad." , :class => :sad } ]
      builder.data.should == [ { :status => "I am happy!", :class => :happy },
                               { :status => "I am sad." , :class => :sad } ]
    end
  end
  
  describe "generating features" do
    before do
      @builder = FeatureSet::Builder.new
      @builder.add_feature_builder FeatureSet::FeatureBuilder::Cuss.new
      @builder.add_data :status => "this is some text", :class => :awesome
      @builder.add_data :status => "this is some shitty text", :class => :less_awesome
    end
    
    it "should output a row of features for every line of data" do
      @builder.generate_features
      @builder.features[0].should == { :status_cuss_count => 0, :class => :awesome }
      @builder.features[1].should == { :status_cuss_count => 1, :class => :less_awesome }
    end
    
    it "should make it easy to keep the original data" do
      @builder.generate_features(:include_original => true)
      @builder.features[0].should == { :status => "this is some text", :status_cuss_count => 0, :class => :awesome }
      @builder.features[1].should == { :status => "this is some shitty text", :status_cuss_count => 1, :class => :less_awesome }
    end

    it "should generate features for every string" do
      @builder.add_data :status => "text", :foo => "more shitty text", :class => :awesome
      @builder.generate_features
      @builder.features[1].should == { :status_cuss_count => 1, :class => :less_awesome }
      @builder.features[2].should == { :status_cuss_count => 0, :foo_cuss_count => 1, :class => :awesome }
    end

    it "should allow generation of features on new data while leaving the old data intact" do
      @builder.generate_features
      num_features = @builder.features.length
      @builder.generate_features_for([{ :status => "is this shitty text?" }, { :status => "foo bar" }]).should == [{ :status_cuss_count => 1 }, { :status_cuss_count => 0 }]
      @builder.features.length.should == num_features
    end
  end

  describe "outputing an ARFF file" do
    before do
      @builder = FeatureSet::Builder.new
      @builder.add_feature_builder FeatureSet::FeatureBuilder::Cuss.new
      @builder.add_data :status => "this is some text", :foo => 2, :class => :awesome
      @builder.add_data :status => "this is some shitty text", :foo => 5, :class => :less_awesome
    end

    describe "as an rarff relation" do
      it "should return a rarff relation object" do
        @builder.generate_features(:include_original => { :except => :status })
        arff = @builder.to_rarff
        arff.should be_a(Rarff::Relation)
        arff.attributes.map(&:name).should =~ ["status_cuss_count", "class", "foo"]
        arff.attributes.last.name.should == "class"
        arff.to_s.should =~ /Data/
        arff.to_s.should =~ /status_cuss_count/
      end
    end
    
    describe "as a numeric arff" do
      it "should output an arff to an IO object" do
        @builder.generate_features(:include_original => { :except => :status })
        io = StringIO.new
        @builder.output_numeric_arff(io)
        io.rewind
        io.read.should =~ /@ATTRIBUTE status_cuss_count NUMERIC/
      end
    end
  end
end
