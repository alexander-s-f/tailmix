# frozen_string_literal: true

module Tailmix
  class ActionDSL
    def initialize(action_data)
      @action_data = action_data
    end

    def element(name, classes)
      @action_data[:elements][name.to_sym] = classes.split
    end
  end

  class DSL
    def initialize(definition)
      @definition = definition
      @context = []
    end

    private

    def element(name, base_classes = "", &block)
      if @context.last&.key?(:elements)
        raise Error, "Cannot define a new element `#{name}` inside an `action` block. Use `element` only to specify classes for the action."
      end

      element_data = { base: base_classes.split, options: {} }
      @definition.elements[name.to_sym] = element_data

      if block_given?
        @context.push(element_data)
        instance_eval(&block)
        @context.pop
      end
    end

    def action(name, **kwargs, &block)
      action_data = { elements: {} }.merge(kwargs)
      @definition.actions[name.to_sym] = action_data

      if block_given?
        ActionDSL.new(action_data).instance_eval(&block)
      end
    end

    def method_missing(name, *args, &block)
      current_element = @context.last
      raise NoMethodError, "Undefined method `#{name}`. Dimensions like `#{name}` can only be used inside an `element` block." unless current_element && current_element.key?(:options)

      dimension_data = { options: {}, default: nil }
      current_element[:options][name.to_sym] = dimension_data

      @context.push(dimension_data)
      instance_eval(&block)
      @context.pop
    end

    def respond_to_missing?(method_name, include_private = false)
      @context.last && @context.last.key?(:options) || super
    end

    def option(value, classes, default: false)
      current_dimension = @context.last
      raise "The `option` method can only be used inside a dimension block (e.g. `size do ... end`)" unless current_dimension && current_dimension.key?(:options)

      current_dimension[:options][value] = classes.split
      current_dimension[:default] = value if default
    end
  end
end
