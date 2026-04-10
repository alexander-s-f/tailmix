# frozen_string_literal: true

require_relative "tailmix/version"
require_relative "tailmix/configuration"
require_relative "tailmix/dsl"
require_relative "tailmix/runtime/facade"
require_relative "tailmix/component_store"

ENV["TAILMIX_DEBUG"] = "true"

module Tailmix
  class Error    < StandardError; end
  class DSLError < StandardError; end

  def self.included(base)
    base.extend(DSL)
  end

  # Build a Facade for this component.
  #
  # All keyword arguments are split into:
  #   - variants  (declared with `variant :name, default: ...`)
  #   - state     (everything else)
  #
  # Example:
  #   @ui = tailmix(size: :lg, intent: :primary, open: false)
  def tailmix(initial_args = {})
    facade_class = self.class.tailmix_facade_class
    raise Error, "Tailmix not defined for #{self.class}" unless facade_class

    definition = facade_class.definition

    # Resolve variants with defaults
    variant_keys    = definition[:variants].keys.map(&:to_sym)
    resolved_variants = {}
    resolved_state    = {}

    initial_args.compact.each do |k, v|
      if variant_keys.include?(k.to_sym)
        resolved_variants[k.to_s] = v
      else
        resolved_state[k.to_s] = v
      end
    end

    # Apply variant defaults for any not supplied
    definition[:variants].each do |name, config|
      resolved_variants[name] ||= config[:default]
    end

    merged_state = definition[:states].merge(resolved_state)

    facade_class.new(merged_state, resolved_variants)
  end
end

require_relative "tailmix/engine" if defined?(Rails)
