# frozen_string_literal: true

class DimensionBuilder
  attr_reader :options

  def initialize(default: nil)
    @options = { options: {}, default: default }
  end

  def option(value, classes, default: false)
    @options[:options][value] = classes.split
    if default && @options[:default].nil?
      @options[:default] = value
    end
  end
end
