# This library is alpha and is not yet finished.

# FeatureSet

A Ruby library for building machine learning datasets.

In machine learning, feature selection is often more difficult than algorithm selection.  For many classes of problems, any reasonably modern algorithm can be used (i.e., a SVM, decision tree, etc.).  However, all of these algorithms require information-rich features to learn from, and finding and constructing those features can is often its own engineering challenge.  FeatureSet is a library that makes it easy to construct features from your data as a pre-processing step before applying a modern machine learning library such as Weka or libsvm.

FeatureSet takes a dataset consisting of hashes, with any any object as the value of each key, and builds features from these values as appropriate.  For example, a string value could be expanded into a number of new features- a count of cuss words in the string, a count of slang, a sentiment score, and/or a complete word vector with TF-IDF values.

FeatureSet is extensible, so anyone can write new FeatureBuilders that know to which datatypes they can be applied.  The set of included feature builders expands as the community submits new ones.

## FeatureBuilders

## Example Code

    builder = FeatureSet::DataSet.new
    builder.add_feature_builder FeatureSet::FeatureBuilders::WordVector.new(:word_limit => 2000, :idf_cutoff => 8.0)
    builder.add_feature_builder FeatureSet::FeatureBuilders::Cuss.new
    builder.add_data :status => "This is a spam email", :class => :spam
    builder.add_data :status => "This is a not spam", :class => :not_spam
    builder.build_features(:include_original => false) #do not include :status as it's own column in the output

    # The following ARFF can be imported into Weka
    puts builder.to_rarff.to_s

See the specs for more usage examples.
