require "feature_set/feature_builders/base"

module FeatureSet
  module FeatureBuilders
    class Cuss < Base
      CUSS_WORDS = File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', 'data', 'cusswords.txt'))).split("\n").map {|i| i.strip.downcase }
      
      def build_features(datum, key, row)
        return {} unless datum.value.is_a?(String)
        { :cuss_count => (datum.tokens & CUSS_WORDS).length }
      end
    end
  end
end
