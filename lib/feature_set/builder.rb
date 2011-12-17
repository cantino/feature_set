require 'active_support'
require 'active_support/inflector'

require "feature_set/feature_builder/word_vector"
require "feature_set/feature_builder/cuss"

require "feature_set/datum"

module FeatureSet
  class Builder
    BUILTIN_FEATURE_BUILDERS = %w[FeatureSet::FeatureBuilder::Cuss 
                                  FeatureSet::FeatureBuilder::WordVector].map(&:constantize)

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

    def arff
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
    
    def generate_features(opts = {})
      wrapped_data = self.class.wrap_dataset(data)
      feature_builders.each {|fb| fb.before_generate_features(wrapped_data) }
      @features = generate_features_for(wrapped_data, opts.merge(:already_wrapped => true))
    end

    def generate_features_for(data, opts = {})
      # FYI, we explicitly do not call before_generate_features because this can be used on unknown rows for classification, and
      # we want our feature generators to keep any cached data from the previous 'generate_features' feature building call.  This is
      # important for Wordvector, for example, since it needs to build the idf mappings beforehand and we want them used on any new data.
      wrapped_data = opts[:already_wrapped] ? data : self.class.wrap_dataset(data)
      wrapped_data.map do |row|
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
            builder.generate_features(datum, key, row).each do |feature, value|
              output_row["#{key}_#{feature}".to_sym] = value
            end
          end
        end
        
        output_row
      end
    end

    def add_feature_builders(*builders)
      builders = BUILTIN_FEATURE_BUILDERS.map(&:new) if [:all, "all"].include?(builders.first)
      (@feature_builders << builders).flatten!
    end
    alias_method :add_feature_builder, :add_feature_builders
    
    def self.wrap_dataset(dataset)
      dataset.map { |row| row.inject({}) { |m, (k, v)| m[k] = (k == :class ? v : Datum.new(v)) ; m } }
    end
  end
end
