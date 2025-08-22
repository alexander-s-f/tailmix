# frozen_string_literal: true

module Tailmix
  module Runtime
    class FacadeBuilder
      def self.build(definition)
        Class.new(Tailmix::Runtime::Context) do
          definition.elements.each_key do |element_name|
            define_method(element_name) do |runtime_dimensions = {}|
              attributes_for(element_name, runtime_dimensions)
            end
          end
        end
      end
    end
  end
end
