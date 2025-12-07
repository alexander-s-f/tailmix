# frozen_string_literal: true

require_relative "../ast/visitor"

module Tailmix
  module Visitors
    class DebugPrinter < AST::Visitor
      def initialize
        @indent = 0
      end

      def print!(node)
        @indent = 0
        visit(node)
      end

      private

      def indent
        "  " * @indent
      end

      def with_indent
        @indent += 1
        yield
        @indent -= 1
      end

      public

      def visit_Component(node)
        puts "#{indent}Component(#{node.name})"
        with_indent do
          puts "#{indent}States:"
          visit_all(node.states)
          puts "#{indent}Elements:"
          visit_all(node.elements)
        end
      end

      def visit_StateDefinition(node)
        puts "#{indent}State(#{node.name}, default: #{node.default_value.inspect})"
      end

      def visit_ElementDefinition(node)
        puts "#{indent}Element(#{node.name})"
        with_indent do
          visit_all(node.rules)
        end
      end

      def visit_EventRule(node)
        puts "#{indent}On(#{node.event_name}) ->"
        with_indent { visit(node.instruction_sequence) }
      end

      def visit_StyleRule(node)
        condition_str = node.condition ? "if #{capture_visit(node.condition)}" : "always"
        puts "#{indent}Style(#{condition_str}) ->"
      end

      def visit_Block(node)
        visit_all(node.instructions)
      end

      def visit_Assignment(node)
        print "#{indent}Set: "
        visit(node.target)
        print " = "
        visit(node.value)
        puts ""
      end

      def visit_Log(node)
        print "#{indent}Log: "
        args = node.arguments.map { |arg| capture_visit(arg) }.join(", ")
        puts args
      end

      def capture_visit(node)
        case node
        when AST::Literal then node.value.inspect
        when AST::VariableReference then "#{node.domain}.#{node.path.join('.')}"
        when AST::BinaryOp
          "(#{capture_visit(node.left)} #{node.operator} #{capture_visit(node.right)})"
        else
          "<#{node.type_name}>"
        end
      end

      def visit_Literal(node)
        print node.value.inspect
      end

      def visit_VariableReference(node)
        print "#{node.domain}.#{node.path.join('.')}"
      end

      def visit_BinaryOp(node)
        visit(node.left)
        Kernel.print " #{node.operator} "
        visit(node.right)
      end

      def visit_primitive(node)
        print node.inspect
      end
    end
  end
end
