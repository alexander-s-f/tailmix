# frozen_string_literal: true

module Tailmix
  module Definition
    module Builders
      class StateBuilder
        def initialize
          @data_source = {}
        end

        def endpoint(method, url:)
          @data_source = { method: method, url: url }
        end

        def build_data_source
          @data_source.empty? ? nil : @data_source.freeze
        end
      end
    end
  end
end
