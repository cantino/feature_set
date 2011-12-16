module FeatureSet
  module FeatureBuilder
    class Base
      attr_accessor :options
      
      def initialize(options = {})
        @options = options
      end
      
      def generate_features(datum, key, row)
        raise "Please implement 'generate_features' in your subclass of FeatureBuilder::Base."
      end
      
      def before_generate_features(dataset)
      end
    end
  end
end
