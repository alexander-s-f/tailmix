# frozen_string_literal: true

module Tailmix
  module Definition
    module Contexts
      module Actions
        class ElementBuilder
          def initialize(default_method)
            @default_method = default_method
            @commands = []
          end

          def classes(classes_string, method: @default_method)
            @commands << { field: :classes, method: method, payload: classes_string }
          end

          def data(data_hash)
            operation = data_hash.delete(:method) || @default_method

            @commands << { field: :data, method: operation, payload: data_hash }
          end

          def build_commands
            @commands
          end
        end
      end
    end
  end
end
