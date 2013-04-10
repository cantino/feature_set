module FeatureSet
  module FeatureBuilders
    class Base
      attr_accessor :options, :data_set
      
      def initialize(options = {})
        @options = options
      end
      
      def build_features(datum, key, row)
        raise "Please implement 'build_features' in your subclass of FeatureBuilders::Base."
      end

      def before_build_features(dataset)
      end

      def verbose?
        data_set && data_set.verbose
      end
    end
  end
end
