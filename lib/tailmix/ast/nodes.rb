# frozen_string_literal: true

module Tailmix
  module AST
    # --- Root nodes ---
    Root = Struct.new(:name, :states, :actions, :elements, :plugins, keyword_init: true)
    State = Struct.new(:name, :options, keyword_init: true)
    Element = Struct.new(:name, :base_classes, :rules, :default_attributes, :variant_classes, keyword_init: true)
    Action = Struct.new(:name, :instructions, keyword_init: true)
    Plugin = Struct.new(:name, :options, keyword_init: true)

    # --- Rules for Elements ---
    LetRule = Struct.new(:variable_name, :expression, :options, keyword_init: true)
    DimensionRule = Struct.new(:condition, :variants, keyword_init: true)
    CompoundVariantRule = Struct.new(:conditions, :classes, keyword_init: true)
    BindingRule = Struct.new(:attribute, :expression, :is_content, keyword_init: true)
    EventHandlerRule = Struct.new(:event, :action_name, :inline_action, keyword_init: true)
    ModelBindingRule = Struct.new(:target_expression, :state_expression, :options, keyword_init: true)

    # --- Options for DimensionRule ---
    Variant = Struct.new(:value, :classes, keyword_init: true)

    # --- Nodes for Action (instructions) ---
    Instruction = Struct.new(:operation, :args, keyword_init: true)
    FetchInstruction = Struct.new(:url, :options, :on_success, :on_error, keyword_init: true)
    DebounceInstruction = Struct.new(:delay, :instructions, keyword_init: true)

    # --- Expression Nodes ---
    Value = Struct.new(:value, keyword_init: true)
    Property = Struct.new(:source, :path, keyword_init: true)
    BinaryOperation = Struct.new(:operator, :left, :right, keyword_init: true)
    UnaryOperation = Struct.new(:operator, :operand, keyword_init: true)
    CollectionOperation = Struct.new(:collection, :operation, :args, keyword_init: true)
    FunctionCall = Struct.new(:name, :args, keyword_init: true)
    TernaryOperation = Struct.new(:condition, :then_expr, :else_expr, keyword_init: true)
  end
end