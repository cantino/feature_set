require 'active_support'
require 'active_support/inflector'

require "feature_set/feature_builder/word_vector"
require "feature_set/feature_builder/cuss"

require "feature_set/datum"

module FeatureSet
  class Builder
    BUILTIN_FEATURE_BUILDERS = %w[FeatureSet::FeatureBuilder::Cuss 
                                  FeatureSet::FeatureBuilder::WordVector].map(&:constantize)

    attr_accessor :options, :feature_builders, :data, :features

    def initialize(options = {})
      @options = options
      @feature_builders = []
      @features = []
      @data = []
    end
    
    def add_data(data)
      clear_features
      (@data << data).flatten!
    end
    
    def clear_data
      @data = []
      clear_features
    end
    
    def clear_features
      @features = []
    end
    
    def generate_features(opts = {})
      wrapped_data_set = self.class.wrap_dataset(data)

      feature_builders.each {|fb| fb.before_generate_features(wrapped_data_set) }
      
      @features = wrapped_data_set.map do |row|
        output_row = {}
        
        row.each do |key, datum|
          (output_row[:class] = datum) and next if key == :class
          output_row[key] = datum.value if opts[:include_original]

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
