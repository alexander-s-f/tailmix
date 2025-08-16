# frozen_string_literal: true

module Tailmix
  class ActionProxy
    def initialize(runtime, action_name)
      @runtime = runtime
      @action_name = action_name.to_sym
    end

    def apply!
      action_def = @runtime.definition.actions[@action_name]
      raise Error, "Action `#{@action_name}` not found in Tailmix definition." unless action_def

      manipulation_method = action_def.fetch(:method, :add).to_sym
      unless Element.public_instance_methods.include?(manipulation_method)
        raise Error, "Invalid method `#{manipulation_method}` for action `#{@action_name}`. Must be :add, :remove, or :toggle."
      end

      action_def[:elements].each do |element_name, classes_to_change|
        element = @runtime.public_send(element_name)
        element.public_send(manipulation_method, classes_to_change)
      end

      @runtime
    end

    def to_h
      action_def = @runtime.definition.actions[@action_name]
      return {} unless action_def

      payload = {
        action: @action_name,
        method: action_def.fetch(:method, :add)
      }

      payload[:elements] = action_def[:elements].transform_values do |classes_array|
        { class: classes_array.join(" ") }
      end

      payload
    end

    def data
      { "tailmix_#{@action_name}_payload": to_h.to_json }
    end

    def stimulus(controller_name)
      key = "#{controller_name}_#{@action_name}_action_value".to_sym
      { key => to_h.to_json }
    end
  end
end
