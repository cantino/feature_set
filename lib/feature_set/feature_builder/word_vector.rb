require "feature_set/feature_builder/base"

module FeatureSet
  module FeatureBuilder
    class WordVector < Base
      attr_accessor :idfs

      def initialize(options = {})
        super
      end

      def before_generate_features(dataset)
        @idfs = {}
        dataset.each do |row|
          row.each do |key, datum|
            next if key == :class
            if datum.value.is_a?(String)
              idfs[key] ||= {}
              datum.token_counts.keys.each do |token|
                idfs[key][token] ||= 0
                idfs[key][token] += 1
              end
            end
          end
        end
        
        num_docs = dataset.length
        STDERR.puts "Done building df counts.  The dataset has #{num_docs} documents."
        pruned = 0
        idfs.each do |feature, freqs|
          new_freqs = {}
          freqs.each do |key, value|
            log = Math.log(num_docs / value.to_f)
            if log < 6.0
              new_freqs[key] = log
            else
              pruned += 1
            end
          end
          idfs[feature] = new_freqs
        end
        STDERR.puts "Done calculating idfs.  Pruned #{pruned} rare values."
      end
      
      def generate_features(datum, key, row)
        return {} unless datum.value.is_a?(String)
        num_words = datum.tokens.length.to_f
        idfs[key].inject({}) do |memo, (word, idf)|
          memo[word] = ((datum.token_counts[word] || 0) / num_words) * idf
          memo
        end
      end
    end
  end
end
