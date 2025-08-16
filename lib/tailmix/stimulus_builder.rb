# frozen_string_literal: true

require "json"

module Tailmix
  class StimulusBuilder
    def initialize(definition, element: nil)
      @definition = definition
      @element = element
      @data_attributes = {}
      @current_controller = nil
    end

    def controller(name)
      context(name)
      (@data_attributes[:controller] ||= []).push(@current_controller).uniq!
      self
    end

    def context(name)
      @current_controller = name.to_s
      self
    end

    def action(actions_hash)
      ensure_controller_context!
      actions_string = actions_hash.map { |event, method| "#{event}->#{@current_controller}##{method}" }.join(" ")
      @data_attributes[:action] = [@data_attributes[:action], actions_string].compact.join(" ").strip
      self
    end

    def target(target_name)
      ensure_controller_context!
      key = :"#{@current_controller}-target"
      @data_attributes[key] = [@data_attributes[key], target_name.to_s].compact.join(" ").strip
      self
    end

    def param(params_hash)
      ensure_controller_context!
      params_hash.each do |key, value|
        param_key = :"#{@current_controller}-#{key.to_s.gsub('_', '-')}-param"
        @data_attributes[param_key] = value
      end
      self
    end

    def value(action_name)
      ensure_controller_context!
      action_def = @definition.actions[action_name.to_sym]
      raise Error, "Action `#{action_name}` not found..." unless action_def

      payload = {
        action: action_name,
        method: action_def.fetch(:method, :add),
        elements: action_def[:elements].transform_values { |classes| { class: classes.join(" ") } }
      }

      key = :"#{@current_controller}-#{action_name.to_s.gsub('_', '-')}-action-value"
      @data_attributes[key] = payload.to_json
      self
    end

    def to_h
      if @data_attributes[:controller]
        @data_attributes[:controller] = @data_attributes[:controller].join(" ")
      end

      if @element
        { class: @element.to_s, data: @data_attributes }
      else
        { data: @data_attributes }
      end
    end

    private

    def ensure_controller_context!
      raise Error, "A controller context must be set with `.controller(name)` or `.context(name)` before calling this method." unless @current_controller
    end
  end
end
