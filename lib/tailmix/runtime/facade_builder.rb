# frozen_string_literal: true

module Tailmix
  module Runtime
    class FacadeBuilder
      def self.build(definition)
        Class.new(Tailmix::Runtime::Context) do
          definition.elements.each_key do |element_name|
            define_method(element_name) do |with = {}|
              attributes_for(element_name, with: with)
            end
          end

          alias_method :action, :action_proxy

          def inspect
            "#<Tailmix::UI for #{component_name} state=#{state.inspect}>"
          end
        end
      end
    end
  end
end
