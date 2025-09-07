# frozen_string_literal: true

require_relative "tailmix/version"
require_relative "tailmix/configuration"
require_relative "tailmix/dsl"
require_relative "tailmix/definition"
require_relative "tailmix/runtime"
require_relative "tailmix/middleware/registry_cleaner"
require_relative "tailmix/view_helpers"

module Tailmix
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  def self.included(base)
    base.extend(DSL)
  end

  def tailmix(id: nil, **initial_state)
    self.class.tailmix_facade_class.new(self, self.class.tailmix_definition, initial_state, id: id)
  end
end

require_relative "tailmix/engine" if defined?(Rails)
