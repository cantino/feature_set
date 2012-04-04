module FeatureSet
  class Datum
    TOKEN_REGEX = /[\s\/]+/
    NON_ASCII_REGEX = /[^a-zA-Z0-9_\-\']/

    attr_accessor :value

    def initialize(v)
      self.value = v
    end

    def tokens
      @tokens ||= begin
        value.strip.gsub(/^['"]/, '').gsub(/["']$/, '').downcase.gsub(NON_ASCII_REGEX, ' ').split(TOKEN_REGEX).reject {|t| t.empty? }
      end
    end

    def token_counts
      @token_counts ||= begin
        tokens.inject({}) { |m, w| m[w] ||= 0; m[w] += 1; m }
      end
    end
  end
end