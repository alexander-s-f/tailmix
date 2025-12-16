# frozen_string_literal: true

module Tailmix
  module AST
    class Node
      def accept(visitor)
        visitor.visit(self)
      end

      def type_name
        self.class.name.split("::").last
      end
    end

    # Mixin for convenience, to avoid duplicating accept in each class
    module NodeMethods
      def accept(visitor)
        visitor.visit(self)
      end

      def type_name
        self.class.name.split("::").last
      end
    end

    # --- 1. Definitions ---
    Component = Struct.new(:name, :states, :elements, :boot_sequence, keyword_init: true) do
      include NodeMethods
    end

    # StateDefinition = Struct.new(:name, :default_value, :type, keyword_init: true) do
    #   include NodeMethods
    # end

    class StateDefinition
      include NodeMethods
      attr_reader :name, :default_value, :persistence

      def initialize(name, default_value, persistence: nil)
        @name = name
        @default_value = default_value
        @persistence = persistence # {:type => :hash, :key => "tab"}
      end
    end

    ElementDefinition = Struct.new(:name, :attributes, :rules, keyword_init: true) do
      include NodeMethods
    end

    # --- 2. Rules ---
    AttributeEffect = Struct.new(:classes, :data, :aria, :other, keyword_init: true) do
      include NodeMethods
    end

    StyleRule = Struct.new(:condition, :consequent, :alternate, keyword_init: true) do
      include NodeMethods
    end

    MatchRule = Struct.new(:subject, :cases, :default_case, keyword_init: true) do
      include NodeMethods
    end

    EventRule = Struct.new(:event_name, :instruction_sequence, keyword_init: true) do
      include NodeMethods
    end

    # --- 3. Instructions ---
    Block = Struct.new(:instructions, keyword_init: true) do
      include NodeMethods
    end

    Assignment = Struct.new(:target, :value, keyword_init: true) do
      include NodeMethods
    end

    Log = Struct.new(:arguments, keyword_init: true) do
      include NodeMethods
    end

    # --- 4. Expressions ---
    Literal = Struct.new(:value, keyword_init: true) do
      include NodeMethods
    end

    VariableReference = Struct.new(:domain, :path, keyword_init: true) do
      include NodeMethods
    end

    BinaryOp = Struct.new(:left, :operator, :right, keyword_init: true) do
      include NodeMethods
    end

    UnaryOp = Struct.new(:operator, :operand, keyword_init: true) do
      include NodeMethods
    end

    # Connect the module to all structures
    constants.each do |const|
      klass = const_get(const)
      klass.include(NodeMethods) if klass.is_a?(Class) && klass < Struct
    end
  end
end
