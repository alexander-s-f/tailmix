# frozen_string_literal: true

require_relative "tailmix/version"
require_relative "tailmix/definition"
require_relative "tailmix/runtime"
require_relative "tailmix/action_proxy"
require_relative "tailmix/stimulus_builder"

module Tailmix
  class Error < StandardError; end

  module ClassMethods
    def tailmix(&block)
      @tailmix_definition = Definition.new(&block)
    end

    def tailmix_definition
      @tailmix_definition || raise(Error, "Tailmix definition not found in #{self.name}")
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def tailmix(options = {})
    Runtime.new(self.class.tailmix_definition, options)
  end
end