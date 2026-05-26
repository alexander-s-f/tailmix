# frozen_string_literal: true

module Tailmix
  module AST
    # Mixin with common logic
    module NodeMethods
      def accept(visitor)
        visitor.visit(self)
      end

      def type_name
        self.class.name.split("::").last
      end

      # Key access support: response['id'] or state.user['name']
      def [](key)
        # Returning a new VariableReference, deepening the path
        # ATTENTION: This only works if self is a VariableReference.
        # If self is an expression (BinaryOp), then this cannot be done (you need to add Operation :get).

        if self.is_a?(VariableReference)
          # Creating a new link with an extended path: path + [key]
          VariableReference.new(domain: self.domain, path: self.path + [key.to_s])
        else
          # Fallback for access operation (for JS: obj[key])
          # method: :get, arguments: [key]
          MethodCall.new(object: self, method: :get, arguments: [key])
        end
      end

      # Sugar to create a MethodCall node directly from an AST node
      # Allows writing in DSL: state.query.length
      def length
        MethodCall.new(object: self, method: :length, arguments: [])
      end

      def +(other)
        binary_op(:add, other)
      end

      def -(other)
        binary_op(:sub, other)
      end

      def *(other)
        binary_op(:mul, other)
      end

      def /(other)
        binary_op(:div, other)
      end

      # --- Comparison Operators ---

      # In Ruby, overloading == is dangerous for hashes, but for DSL objects within Struct
      # it is permissible if we understand the consequences.
      # We want to write: condition: state.active == param.id
      def ==(other)
        binary_op(:eq, other)
      end

      def !=(other)
        binary_op(:neq, other)
      end

      def >(other)
        binary_op(:gt, other)
      end

      def <(other)
        binary_op(:lt, other)
      end

      def >=(other)
        binary_op(:gte, other)
      end

      def <=(other)
        binary_op(:lte, other)
      end

      # --- Logical Operators ---

      # Ruby does not allow overloading && and ||.
      # We use bitwise operators & and | or named methods.

      def &(other)
        binary_op(:and, other)
      end
      alias_method :and, :&

      def |(other)
        binary_op(:or, other)
      end
      alias_method :or, :|

      # Helper for negation (!state.active)
      def !
        UnaryOp.new(operator: :not, operand: self)
      end

      private

      def binary_op(operator, right)
        # If the right-hand side is a simple number/string, wrap it in Literal.
        # This simplifies the JSON generator.
        right_node = if right.is_a?(NodeMethods) # Checking if this is an AST node
          right
        else
          Literal.new(value: right)
        end

        BinaryOp.new(left: self, operator: operator, right: right_node)
      end
    end

    class Node
      include NodeMethods
    end

    # --- 1. Definitions ---
    Component = Struct.new(:name, :states, :variants, :elements, :boot_sequence, :watchers, keyword_init: true) do
      include NodeMethods
    end

    class StateDefinition
      include NodeMethods
      attr_reader :name, :default_value, :persistence, :type

      def initialize(name, default_value, persistence: nil, type: nil)
        @name = name
        @default_value = default_value
        @persistence = persistence
        @type = type
      end
    end

    class VariantDefinition
      include NodeMethods
      attr_reader :name, :default_value

      def initialize(name, default_value)
        @name = name
        @default_value = default_value
      end
    end

    ElementDefinition = Struct.new(:name, :attributes, :rules, keyword_init: true) do
      include NodeMethods
    end

    # --- 2. Rules ---
    AttributeEffect = Struct.new(:classes, :data, :aria, :props, :other, :html, keyword_init: true) do
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

    Toggle = Struct.new(:target, keyword_init: true) do
      include NodeMethods
    end

    Log = Struct.new(:arguments, keyword_init: true) do
      include NodeMethods
    end

    Fetch = Struct.new(:url, :options, :success_block, keyword_init: true) do
      include NodeMethods
    end

    Dispatch = Struct.new(:event_name, :detail, keyword_init: true) do
      include NodeMethods
    end

    WatchRule = Struct.new(:subject, :instruction_sequence, keyword_init: true) do
      include NodeMethods
    end

    # --- 4. Expressions ---
    Literal = Struct.new(:value, keyword_init: true) do
      include NodeMethods
    end

    # We use this same node for state.active and event.value
    # event.value -> domain: :event, path: ["value"]
    VariableReference = Struct.new(:domain, :path, keyword_init: true) do
      include NodeMethods
    end

    BinaryOp = Struct.new(:left, :operator, :right, keyword_init: true) do
      include NodeMethods
    end

    UnaryOp = Struct.new(:operator, :operand, keyword_init: true) do
      include NodeMethods
    end

    # Method invocation node (e.g., .length)
    MethodCall = Struct.new(:object, :method, :arguments, keyword_init: true) do
      include NodeMethods
    end

    # Connect the module to all structures
    constants.each do |const|
      klass = const_get(const)
      if klass.is_a?(Class) && klass < Struct
        klass.include(NodeMethods)
      end
    end
  end
end
