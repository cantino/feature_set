require "feature_set/feature_builders/base"

module FeatureSet
  module FeatureBuilders
    class WordVector < Base
      attr_accessor :idfs

      # Options:
      #   :tf_only => true|false, default is false
      #   :idf_cutiff => <cutoff>, default is 10
      #   :word_limit => <word limit>, default is 2000
      def initialize(options = {})
        super
        @idfs = {}
      end

      def before_build_features(dataset)
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
        idf_cutoff = (options[:idf_cutoff] || 10).to_f
        word_limit = options[:word_limit] || 2000
        STDERR.puts "Done building df counts.  The dataset has #{num_docs} documents." if verbose?

        idfs.each do |feature, freqs|
          pruned = 0
          if options[:tf_only]
            new_freqs = freqs
          else
            new_freqs = {}
            freqs.each do |key, value|
              log = Math.log(num_docs / value.to_f)
              if log < idf_cutoff
                new_freqs[key] = log
              else
                pruned += 1
              end
            end
          end
          if options[:word_limit]
            new_freqs = if options[:tf_only]
                          new_freqs.to_a.sort {|a, b| b.last <=> a.last }
                        else
                          new_freqs.to_a.sort {|a, b| a.last <=> b.last }
                        end
            new_freqs = new_freqs[0...word_limit].inject({}) { |m, (k, v)| m[k] = v; m }
          end
          idfs[feature] = new_freqs
          STDERR.puts "Done calculating idfs for #{feature}.  Pruned #{pruned} rare values, leaving #{idfs[feature].length} values." if verbose?
        end
      end
      
      def build_features(datum, key, row)
        return {} unless datum.value.is_a?(String)
        num_words = datum.tokens.length.to_f
        unless idfs[key]
          STDERR.puts "WARNING: build_features called on untrained data in WordVector.  Are you calling 'data_set.build_features_for' without calling 'data_set.build_features_from_data!' first?"
        end
        if options[:tf_only]
          (idfs[key] || {}).inject({}) do |memo, (word, idf)|
            memo["wv_#{word}"] = ((datum.token_counts[word] || 0) / num_words)
            memo
          end
        else
          (idfs[key] || {}).inject({}) do |memo, (word, idf)|
            memo["wv_#{word}"] = ((datum.token_counts[word] || 0) / num_words) * idf
            memo
          end
        end
      end
    end
  end
end
