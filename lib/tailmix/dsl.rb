# frozen_string_literal: true

require_relative "definition/builders/component_builder"
require_relative "definition/merger"
require_relative "dev/tools"

module Tailmix
  module DSL
    def tailmix(&block)
      child_context = Definition::Builders::ComponentBuilder.new(component_name: self)
      child_context.instance_eval(&block)
      child_definition = child_context.build_definition

      if superclass.respond_to?(:tailmix_definition) && (parent_definition = superclass.tailmix_definition)
        @tailmix_definition = Definition::Merger.call(parent_definition, child_definition)
      else
        @tailmix_definition = child_definition
      end
    end

    def tailmix_definition
      @tailmix_definition || raise(Error, "Tailmix definition not found in #{name}")
    end

    def tailmix_facade_class
      @_tailmix_facade_class ||= Runtime::FacadeBuilder.build(tailmix_definition)
    end

    def dev
      Dev::Tools.new(self)
    end
  end
end