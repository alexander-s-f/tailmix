# frozen_string_literal: true

module Tailmix
  module Utils
    def self.deep_merge(original_hash, other_hash)
      other_hash.each_with_object(original_hash.dup) do |(key, value), result|
        if value.is_a?(Hash) && result[key].is_a?(Hash)
          result[key] = deep_merge(result[key], value)
        else
          result[key] = value
        end
      end
    end
  end
end
