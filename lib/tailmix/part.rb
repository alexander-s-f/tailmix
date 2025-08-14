# frozen_string_literal: true

require "set"

module Tailmix
  class Part
    def initialize(class_string)
      @classes = Set.new(class_string.to_s.split)
    end

    def add(*new_classes)
      @classes.merge(process_args(new_classes))
      self
    end

    def remove(*classes_to_remove)
      @classes.subtract(process_args(classes_to_remove))
      self
    end

    def toggle(*classes_to_toggle)
      process_args(classes_to_toggle).each do |cls|
        @classes.delete?(cls) || @classes.add(cls)
      end
      self
    end

    def to_s
      @classes.to_a.join(" ")
    end
    alias to_str to_s

    private

    def process_args(args)
      args.flat_map { |arg| arg.to_s.split }
    end
  end
end
