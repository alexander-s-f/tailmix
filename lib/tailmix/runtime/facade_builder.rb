# frozen_string_literal: true

module Tailmix
  module Runtime
    class FacadeBuilder
      def self.build(definition)
        Class.new(Tailmix::Runtime::Context) do
          definition.elements.each_key do |element_name|
            define_method(element_name) do
              attributes_for(element_name)
            end
          end

          alias_method :state, :state_proxy
          alias_method :action, :action_proxy

          def inspect
            # elements_list = @definition.elements.keys.join(", ")
            #  "#<Tailmix::UI for #{component_name} elements=[#{elements_list}] dimensions=#{@dimensions.inspect}>"
            "#<Tailmix::UI for #{component_name} state=#{get_state.inspect}>"
          end
        end
      end
    end
  end
end
