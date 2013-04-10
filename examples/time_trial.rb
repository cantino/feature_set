# See how we do with a large amount of data.

$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'feature_set'
require 'benchmark'

data_set = FeatureSet::DataSet.new
data_set.add_feature_builder FeatureSet::FeatureBuilders::WordVector.new(:word_limit => 2000, :idf_cutoff => 8.0)
data_set.add_feature_builder FeatureSet::FeatureBuilders::Cuss.new

WORDS = %w[foo bar baz bing boop bling blop blop plop plip blip]
def random_sentence
  (rand * 20).to_i.times.map { WORDS[rand * WORDS.length] }.join(" ")
end

Benchmark.bm do |benchmark|
  benchmark.report("Insert") do
    (ARGV.first || 50_000).to_i.times do
      data_set.add_data :status => random_sentence, :class => (rand > 0.5 ? :spam : :ham)
    end
  end

  wrapped_data = nil
  benchmark.report("Wrap") do
    wrapped_data = FeatureSet::DataSet.wrap_dataset(data_set.data)
  end

  benchmark.report("Before") do
    data_set.trigger_before_build_features(wrapped_data)
  end

  benchmark.report("Build") do
    data_set.features = data_set.build_features_for(wrapped_data, { :already_wrapped => true })
  end

  benchmark.report("Output") do
    data_set.to_rarff.to_s
  end
end