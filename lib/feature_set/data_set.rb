require "feature_set/feature_builders/word_vector"
require "feature_set/feature_builders/cuss"
require "feature_set/feature_builders/emoticon"

require "feature_set/datum"

module FeatureSet
  class DataSet
    BUILTIN_FEATURE_BUILDERS = [FeatureSet::FeatureBuilders::Cuss,
                                FeatureSet::FeatureBuilders::Emoticon,
                                FeatureSet::FeatureBuilders::WordVector]

    attr_accessor :options, :feature_builders, :data, :features, :name

    def initialize(options = {})
      @options = options
      @name = options[:name]
      @feature_builders = []
      @features = []
      @data = []
    end

    def add_data(data)
      (@data << data).flatten!
    end

    def clear_data
      @data = []
    end

    def clear_features
      @features = []
    end

    def to_csv
      output = []
      features.each do |feature|
        output << feature.values.join(', ')
      end

      output.join("\n")
    end

    def to_rarff
      relation = Rarff::Relation.new(name || 'Data')
      keys = features.first.keys
      instances = features.map do |row|
        keys.map do |key|
          value = row[key]
          if value.is_a?(String)
            value.gsub(/\\/, "\\\\\\\\").gsub(/"/, "\\\\\"").gsub(/'/, '\\\\\'')
          elsif value.is_a?(Symbol)
            value.to_s
          else
            value
          end
        end
      end
      relation.instances = instances
      keys.each_with_index do |key, index|
        relation.attributes[index].name = key.to_s
      end
      relation
    end

    # This only knows how to output arfs with true/false classes and all numeric attributes.
    # Additionally, every row must have the same attributes.
    def output_numeric_arff(io)
      keys = features.first.keys
      io.puts "@RELATION Data"
      keys.each do |key|
        io.puts "@ATTRIBUTE #{key} NUMERIC" unless key == :class
      end
      io.puts "@ATTRIBUTE class {false,true}"
      io.puts "@DATA"
      features.each do |feature|
        io.puts keys.map { |k| k == :class ? feature[k].to_s : feature[k].to_f }.join(",")
      end
    end

    def build_features_from_data!(opts = {})
      wrapped_data = self.class.wrap_dataset(data)
      feature_builders.each {|fb| fb.before_build_features(wrapped_data) }
      @features = build_features_for(wrapped_data, opts.merge(:already_wrapped => true))
    end

    def build_features_for(data, opts = {})
      # FYI, we explicitly do not call before_build_features because this can be used on unknown rows for classification, and
      # we want our feature builders to keep any cached data from the previous 'build_features_from_data!' call.  This is important for
      # Wordvector, for example, since it needs to build the idf mappings beforehand and needs to re-use them on any new data.
      wrapped_data = opts[:already_wrapped] ? data : self.class.wrap_dataset(data)
      wrapped_data.map.with_index do |row, index|
        output_row = {}

        row.each do |key, datum|
          if key == :class
            output_row[:class] = datum
            next
          end

          if opts[:include_original] && (opts[:include_original].is_a?(TrueClass) || ![opts[:include_original][:except]].flatten.include?(key))
            output_row[key] = datum.value
          end

          feature_builders.each do |builder|
            builder.build_features(datum, key, row).each do |feature, value|
              output_row["#{key}_#{feature}".to_sym] = value
            end
          end
        end

        if index % 10 == 0
          STDERR.print "."; STDERR.flush
        end

        output_row
      end
    end

    def add_feature_builders(*builders)
      builders = BUILTIN_FEATURE_BUILDERS.map(&:new) if [:all, "all"].include?(builders.first)
      (@feature_builders << builders).flatten!
    end
    alias_method :add_feature_builder, :add_feature_builders


    def dump_feature_builders
      Marshal.dump(feature_builders)
    end

    def load_feature_builders(serialized_builders)
      clear_features
      self.feature_builders = Marshal.load(serialized_builders)
    end

    def self.wrap_dataset(dataset)
      dataset = [dataset] unless dataset.is_a?(Array)
      dataset.map { |row| row.inject({}) { |m, (k, v)| m[k] = (k == :class ? v : Datum.new(v)) ; m } }
    end
  end
end
