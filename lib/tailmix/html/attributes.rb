# frozen_string_literal: true

require "erb"
require_relative "class_list"
require_relative "data_map"

module Tailmix
  module HTML
    class Attributes < Hash
      attr_reader :element_name

      def initialize(initial_hash = {}, element_name: nil)
        @element_name = element_name
        super()
        self[:class] = ClassList.new
        self[:data]  = DataMap.new
        merge!(initial_hash)
      end

      def each(&block)
        to_h.each(&block)
      end

      def to_h
        final_attrs = select { |k, _| !%i[class data].include?(k.to_sym) }
        class_string = self[:class].to_s
        final_attrs[:class] = class_string unless class_string.empty?
        final_attrs.merge!(self[:data].to_h)

        debug_attr_name = Tailmix.configuration&.debug_attribute
        if debug_attr_name && defined?(Rails) && Rails.env.development?
          final_attrs[debug_attr_name] = @element_name
        end
        final_attrs
      end
      alias_method :to_hash, :to_h

      def to_s
        classes.to_s
      end

      def classes
        self[:class]
      end

      def data
        self[:data]
      end

      def stimulus
        data.stimulus
      end

      def toggle(class_names)
        classes.toggle(class_names)
        self
      end

      def add(class_names)
        classes.add(class_names)
        self
      end

      def remove(class_names)
        classes.remove(class_names)
        self
      end
    end
  end
end
