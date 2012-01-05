require 'spec_helper'

describe FeatureSet::DataSet do
  describe "adding feature builders" do
    it "can add all known feature builders" do
      data_set = FeatureSet::DataSet.new
      data_set.add_feature_builders :all
      data_set.feature_builders.map {|i| i.class}.should include(FeatureSet::FeatureBuilders::WordVector)
      data_set.feature_builders.length.should == Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "feature_set", "feature_builders", "*.rb"))].length - 1
    end
    
    it "can add individual feature builders" do
      data_set = FeatureSet::DataSet.new
      data_set.add_feature_builders FeatureSet::FeatureBuilders::WordVector.new
      data_set.feature_builders.length.should == 1
    end

    it "can add arrays of feature builders" do
      data_set = FeatureSet::DataSet.new
      data_set.add_feature_builders [FeatureSet::FeatureBuilders::WordVector.new, FeatureSet::FeatureBuilders::Cuss.new]
      data_set.feature_builders.length.should == 2
    end
  end
  
  describe "adding data" do
    it "should accept mappings between one or more strings and their classifications" do
      data_set = FeatureSet::DataSet.new
      data_set.add_data [ { :status => "I am happy!", :class => :happy },
                          { :status => "I am sad." , :class => :sad } ]
      data_set.data.should == [ { :status => "I am happy!", :class => :happy },
                                { :status => "I am sad." , :class => :sad } ]
      data_set.add_data :status => "Something", :another_feature => "Something else", :class => :awesome
      data_set.data.should == [ { :status => "I am happy!", :class => :happy },
                                { :status => "I am sad." , :class => :sad },
                                { :status => "Something", :another_feature => "Something else", :class => :awesome } ]
      data_set.clear_data
      data_set.data.should == []
      data_set.data = [ { :status => "I am happy!", :class => :happy },
                        { :status => "I am sad." , :class => :sad } ]
      data_set.data.should == [ { :status => "I am happy!", :class => :happy },
                                { :status => "I am sad." , :class => :sad } ]
    end
  end
  
  describe "generating features" do
    before do
      @data_set = FeatureSet::DataSet.new
      @data_set.add_feature_builders FeatureSet::FeatureBuilders::Cuss.new
      @data_set.add_data :status => "this is some text", :class => :awesome
      @data_set.add_data :status => "this is some shitty text", :class => :less_awesome
    end
    
    it "should output a row of features for every line of data" do
      @data_set.build_features_from_data!
      @data_set.features[0].should == { :status_cuss_count => 0, :class => :awesome }
      @data_set.features[1].should == { :status_cuss_count => 1, :class => :less_awesome }
    end
    
    it "should make it easy to keep the original data" do
      @data_set.build_features_from_data!(:include_original => true)
      @data_set.features[0].should == { :status => "this is some text", :status_cuss_count => 0, :class => :awesome }
      @data_set.features[1].should == { :status => "this is some shitty text", :status_cuss_count => 1, :class => :less_awesome }
    end

    it "should generate features for every string" do
      @data_set.add_data :status => "text", :foo => "more shitty text", :class => :awesome
      @data_set.build_features_from_data!
      @data_set.features[1].should == { :status_cuss_count => 1, :class => :less_awesome }
      @data_set.features[2].should == { :status_cuss_count => 0, :foo_cuss_count => 1, :class => :awesome }
    end

    it "should allow generation of features on new data while leaving the old data intact" do
      @data_set.build_features_from_data!
      num_features = @data_set.features.length
      @data_set.build_features_for([{ :status => "is this shitty text?" }, { :status => "foo bar" }]).should == [{ :status_cuss_count => 1 }, { :status_cuss_count => 0 }]
      @data_set.features.length.should == num_features
    end
  end
  
  describe "serialization" do
    it "should be able to serialize, saving all trained builders, but not the dataset" do
      data_set = FeatureSet::DataSet.new
      data_set.add_feature_builder FeatureSet::FeatureBuilders::WordVector.new
      data_set.add_data :status => "this is some text", :class => :awesome
      data_set.add_data :status => "this is some shitty text", :class => :less_awesome
      data_set.build_features_from_data!
      trained_rows = data_set.build_features_for([{ :status => "is this shitty text?" }, { :status => "foo bar" }])
      serialized_builders = data_set.dump_feature_builders

      data_set = FeatureSet::DataSet.new
      data_set.add_feature_builder FeatureSet::FeatureBuilders::WordVector.new
      untrained_rows = data_set.build_features_for([{ :status => "is this shitty text?" }, { :status => "foo bar" }])

      data_set2 = FeatureSet::DataSet.new
      data_set2.load_feature_builders(serialized_builders)
      data_set2.data.should == []
      rows_from_dump = data_set2.build_features_for([{ :status => "is this shitty text?" }, { :status => "foo bar" }])
      rows_from_dump.should == trained_rows
      rows_from_dump.should_not == untrained_rows
    end
  end

  describe "outputing an ARFF file" do
    before do
      @data_set = FeatureSet::DataSet.new
      @data_set.add_feature_builders FeatureSet::FeatureBuilders::Cuss.new
      @data_set.add_data :status => "this is some text", :foo => 2, :class => :awesome
      @data_set.add_data :status => "this is some shitty text", :foo => 5, :class => :less_awesome
    end

    describe "as an rarff relation" do
      it "should return a rarff relation object" do
        @data_set.build_features_from_data!(:include_original => { :except => :status })
        arff = @data_set.to_rarff
        arff.should be_a(Rarff::Relation)
        arff.attributes.map(&:name).should =~ ["status_cuss_count", "class", "foo"]
        arff.attributes.last.name.should == "class"
        arff.to_s.should =~ /Data/
        arff.to_s.should =~ /status_cuss_count/
      end
    end
    
    describe "as a numeric arff" do
      it "should output an arff to an IO object" do
        @data_set.build_features_from_data!(:include_original => { :except => :status })
        io = StringIO.new
        @data_set.output_numeric_arff(io)
        io.rewind
        str = io.read
        str.should =~ /@ATTRIBUTE status_cuss_count NUMERIC/
        str.scan(/@ATTRIBUTE class /).length.should == 1
      end
    end
  end
end
