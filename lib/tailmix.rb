# frozen_string_literal: true

require_relative "tailmix/version"
require_relative "tailmix/definition"
require_relative "tailmix/runtime"

module Tailmix
  class Error < StandardError; end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :element_selector_attribute

    def initialize
      element_selector_attribute = nil
    end
  end

  module ClassMethods
    def tailmix(&block)
      context = Definition::ContextBuilder.new
      context.instance_eval(&block)
      @tailmix_definition = context.build_definition
    end

    def tailmix_definition
      @tailmix_definition || raise(Error, "Tailmix definition not found in #{name}")
    end

    def tailmix_facade_class
      @_tailmix_facade_class ||= Runtime::FacadeBuilder.build(tailmix_definition)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def tailmix(options = {})
    facade_class = self.class.tailmix_facade_class
    facade_class.new(self, self.class.tailmix_definition, options)
  end
end

require_relative "tailmix/engine" if defined?(Rails)
