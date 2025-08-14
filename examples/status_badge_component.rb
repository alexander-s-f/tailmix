# frozen_string_literal: true

require_relative "../lib/tailmix"

class StatusBadgeComponent
  include Tailmix

  tailmix do
    element :badge, "inline-flex items-center font-medium px-2.5 py-0.5 rounded-full" do
      size do
        option :sm, "text-xs", default: true
        option :lg, "text-base"
      end
      status do
        option :success, "bg-green-100 text-green-800", default: true
        option :warning, "bg-yellow-100 text-yellow-800"
        option :error,   "bg-red-100 text-red-800"
      end
    end
  end

  attr_reader :classes

  def initialize(status: :success, size: :sm)
    @classes = tailmix(status: status, size: size)
  end

  def highlight!
    @classes.badge.add("ring-2 ring-offset-2 ring-blue-500")
  end

  def render
    "<span class='#{@classes.badge}'>Status</span>"
  end
end

badge1 = StatusBadgeComponent.new(status: :error, size: :lg)
puts "Error badge: #{badge1.render}"
# => Error badge: <span class='inline-flex ... text-base bg-red-100 text-red-800'>Status</span>

badge2 = StatusBadgeComponent.new(status: :success)
badge2.highlight!
puts "Success badge (highlighted): #{badge2.render}"
# => Success badge (highlighted): <span class='inline-flex ... text-xs bg-green-100 text-green-800 ring-2 ring-offset-2 ring-blue-500'>Status</span>
