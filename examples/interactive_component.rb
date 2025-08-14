# frozen_string_literal: true

require_relative "../lib/tailmix"

class InteractiveComponent
  include Tailmix

  tailmix do
    element :container, "p-4 rounded-md"
    element :label, "font-bold"

    action :highlight, behavior: :toggle do
      element :container, "ring-2 ring-blue-500 bg-blue-50"
      element :label, "text-blue-700"
    end
  end

  attr_reader :classes

  def initialize
    @classes = tailmix
  end

  def toggle_highlight
    @classes.actions.highlight.apply!
  end

  def render
    # ...
  end
end

component = InteractiveComponent.new
puts "Initial container: '#{component.classes.container}'"
# => Initial container: 'p-4 rounded-md'

component.toggle_highlight
puts "After highlight:   '#{component.classes.container}'"
# => After highlight:   'p-4 rounded-md ring-2 ring-blue-500 bg-blue-50'

puts "JSON Recipe: #{component.classes.actions.highlight.to_json}"
# => JSON Recipe: {"behavior":"toggle","classes":{"container":"ring-2...","label":"text-blue-700"}}
