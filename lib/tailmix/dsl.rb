# frozen_string_literal: true

require_relative "ast"

module Tailmix
  module DSL

    def tailmix(&block)
      # Parsing: creating an AST-tree
      builder = AST::ComponentBuilder.new(self.name)
      builder.instance_eval(&block)

      # Compilation: Turning the AST into a final, executable structure
      @tailmix_definition = AST::Compiler.call(builder.root_node)
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
