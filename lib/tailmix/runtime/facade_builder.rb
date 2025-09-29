# frozen_string_literal: true

module Tailmix
  module Runtime
    class FacadeBuilder
      def self.build(definition)
        Class.new(Tailmix::Runtime::Context) do
          definition.elements.each do |element|
            define_method(element.name) do |with = {}|
              attributes_for(element.name, with: with)
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
