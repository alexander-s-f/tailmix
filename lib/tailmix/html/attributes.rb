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

        attrs_to_merge = initial_hash.dup

        initial_classes = attrs_to_merge.delete(:class)
        initial_data = attrs_to_merge.delete(:data)
        initial_aria = attrs_to_merge.delete(:aria)

        self[:class] = ClassList.new(initial_classes)
        self[:data]  = DataMap.new("data", initial_data || {})
        self[:aria]  = DataMap.new("aria", initial_aria || {})

        merge!(attrs_to_merge)
      end


      def each(&block)
        to_h.each(&block)
      end
      alias_method :each_pair, :each
      # def each(&block)
      #   to_h.each(&block)
      # end

      def to_h
        final_attrs = select { |k, _| !%i[class data aria].include?(k.to_sym) }

        class_string = self[:class].to_s
        final_attrs[:class] = class_string unless class_string.empty?

        final_attrs.merge!(self[:data].to_h)
        final_attrs.merge!(self[:aria].to_h)

        final_attrs["data-tailmix-element"] = @element_name if @element_name

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

      def aria
        self[:aria]
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

      def each_attribute(&block)
        [ classes: classes, data: data.to_h, aria: aria.to_h ].each(&block)
      end
    end
  end
end
