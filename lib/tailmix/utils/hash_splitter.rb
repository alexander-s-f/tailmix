# frozen_string_literal: true

module Tailmix
  module Utils
    class HashSplitter
      def initialize(*key_groups)
        @key_groups = key_groups
      end

      # Splits the source hash into remainder (unknown keys) and groups (known keys)
      # Returns an array: [remainder, group1, group2, ...]
      def extract(source)
        extracted_groups = @key_groups.map do |keys|
          source.slice(*keys)
        end

        all_known_keys = @key_groups.flatten
        remainder = source.except(*all_known_keys)

        [remainder, *extracted_groups]
      end
    end
  end
end
