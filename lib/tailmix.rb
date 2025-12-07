# frozen_string_literal: true

require_relative "tailmix/version"
require_relative "tailmix/configuration"
require_relative "tailmix/manifest"
require_relative "tailmix/dsl"
require_relative "tailmix/runtime/facade"
require_relative "tailmix/component_store"

ENV["TAILMIX_DEBUG"] = "true"

module Tailmix
  class Error < StandardError; end

  def self.included(base)
    base.extend(DSL)
  end

  def tailmix(initial_state = {})
    facade_class = self.class.tailmix_facade_class
    raise Error, "Tailmix not defined for #{self.class}" unless facade_class

    definition = facade_class.definition

    # FIX: Чистим initial_state от nil значений с помощью .compact
    # Теперь если передать { size: nil }, оно не затрет дефолтное значение.
    cleaned_initial = initial_state.compact.transform_keys(&:to_s)

    merged_state = definition[:states].merge(cleaned_initial)

    facade_class.new(merged_state)
  end
end

require_relative "tailmix/engine" if defined?(Rails)
