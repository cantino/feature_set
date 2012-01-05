require "feature_set/feature_builders/base"

module FeatureSet
  module FeatureBuilders
    class Emoticon < Base
      HAPPY = [">:]", ":-)", ":)", ":o)", ":]", ":3", ":c)", ":>", "=]", "8)", "=)", ":}", ":^)", ">:D", ":-D", ":D", "8-D", "8D", "x-D", "xD", "X-D", "XD", "=-D", "=D", "=-3", "=3"]
      SAD = [":'(", ";*(", ":_(", "T.T", "T_T", "Y.Y", "Y_Y", ">:[", ":-(", ":(", ":-c", ":c", ":-<", ":<", ":-[", ":[", ":{", ">.>", "<.<", ">.<", "D:<", "D:", "D8", "D;", "D=", "DX", "v.v", "D-':"]
      HUMOR = [">;]", ";-)", ";)", "*-)", "*)", ";-]", ";]", ";D", ">:P", ":-P", ":P", "X-P", "x-p", "xp", "XP", ":-p", ":p", "=p", ":-b", ":b"]
      
      def build_features(datum, key, row)
        return {} unless datum.value.is_a?(String)
        tokens = datum.value.split(/\s+/)
        { :happy_emoticon_count => (tokens & HAPPY).length,
          :sad_emoticon_count => (tokens & SAD).length,
          :humor_emoticon_count => (tokens & HUMOR).length }
      end
    end
  end
end
