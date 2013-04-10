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
      data_set.preprocess_data :status => random_sentence, :class => (rand > 0.5 ? :spam : :ham)
    end
  end

  benchmark.report("Build") do
    (ARGV.first || 50_000).to_i.times do
      row = data_set.build_features_for :status => random_sentence, :class => (rand > 0.5 ? :spam : :ham)
    end
  end

  benchmark.report("Output") do
    data_set.to_rarff.to_s
  end
end