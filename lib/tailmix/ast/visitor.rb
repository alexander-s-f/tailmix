# frozen_string_literal: true

module Tailmix
  module AST
    class Visitor
      # Точка входа. Dispatches a method call based on the node class.
      # Example: Literal node -> visit_Literal(node)
      def visit(node)
        if node.respond_to?(:type_name)
          method_name = "visit_#{node.type_name}"

          if respond_to?(method_name)
            public_send(method_name, node)
          else
            visit_generic(node)
          end
        else
          visit_primitive(node)
        end
      end

      def visit_primitive(node)
        # By default, we do nothing; descendants can override.
      end

      # Placeholder method for unknown nodes.
      def visit_generic(node)
        raise NotImplementedError, "#{self.class.name} does not implement visitor for #{node.type_name}"
      end

      def visit_all(nodes)
        nodes.map { |node| visit(node) }
      end
    end
  end
end
