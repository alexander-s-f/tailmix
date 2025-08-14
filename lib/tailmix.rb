# frozen_string_literal: true

require_relative "tailmix/version"
require_relative "tailmix/schema"
require_relative "tailmix/resolver"
require_relative "tailmix/manager"
require_relative "tailmix/part"
require_relative "tailmix/dimension"
require_relative "tailmix/element"
require_relative "tailmix/utils"
require_relative "tailmix/action"

module Tailmix
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_variable_set(:@tailmix_schema, nil)

    base.define_singleton_method(:tailmix_schema) do
      @tailmix_schema
    end

    base.define_singleton_method(:tailmix_schema=) do |value|
      @tailmix_schema = value
    end
  end

  module ClassMethods
    def tailmix(&block)
      self.tailmix_schema = Schema.new(&block)
    end
  end

  private

  def tailmix(options = {})
    Manager.new(self.class.tailmix_schema, options)
  end
end
