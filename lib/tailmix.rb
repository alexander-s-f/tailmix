# frozen_string_literal: true

require_relative "tailmix/version"
require_relative "tailmix/definition"
require_relative "tailmix/runtime"
require_relative "tailmix/dev/tools"

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
      child_context = Definition::ContextBuilder.new
      child_context.instance_eval(&block)
      child_definition = child_context.build_definition

      if superclass.respond_to?(:tailmix_definition) && (parent_definition = superclass.tailmix_definition)
        @tailmix_definition = Definition::Merger.call(parent_definition, child_definition)
      else
        @tailmix_definition = child_definition
      end
    end

    def tailmix_definition
      @tailmix_definition || raise(Error, "Tailmix definition not found in #{name}")
    end

    def tailmix_facade_class
      @_tailmix_facade_class ||= Runtime::FacadeBuilder.build(tailmix_definition)
    end

    def dev
      Dev::Tools.new(self)
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
