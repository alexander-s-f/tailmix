# frozen_string_literal: true

require "json"

module Tailmix
  class Action
    def initialize(manager, behavior:, classes_by_part:)
      @manager = manager
      @behavior = behavior
      @classes_by_part = classes_by_part
    end

    def apply!
      @classes_by_part.each do |part_name, classes|
        part_object = @manager.public_send(part_name)
        part_object.public_send(@behavior, classes)
      end
    end

    def to_json(*_args)
      {
        behavior: @behavior,
        classes: @classes_by_part
      }.to_json
    end
  end
end
