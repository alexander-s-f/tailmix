# frozen_string_literal: true

module Tailmix
  module Definition
    module Contexts
      module Actions
        # This builder captures the desired mutations for a single element
        # within an action's definition.
        class ElementBuilder
          def initialize
            @mutations = {}
          end

          # Defines class mutations.
          # @param classes_string [String]
          def classes(classes_string)
            @mutations[:class] = classes_string
          end

          # Defines data attribute mutations.
          # @param data_hash [Hash]
          def data(data_hash)
            @mutations[:data] = data_hash
          end

          # Returns the captured mutations as a hash.
          def build_mutations
            @mutations
          end
        end
      end
    end
  end
end
