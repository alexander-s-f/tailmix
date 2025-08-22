# frozen_string_literal: true

require "erb"
require "json"
require_relative "stimulus_builder"

module Tailmix
  module HTML
    class DataMap
      MERGEABLE_LIST_ATTRIBUTES = %i[controller action target].freeze

      def initialize(initial_data = {})
        @data = {}
        merge!(initial_data)
      end

      def stimulus
        StimulusBuilder.new(self)
      end

      def merge!(other_data)
        return self unless other_data
        data_to_merge = other_data.is_a?(DataMap) ? other_data.instance_variable_get(:@data) : other_data

        (data_to_merge || {}).each do |key, value|
          key = key.to_sym
          if value.is_a?(Hash) && @data[key].is_a?(Hash)
            @data[key].merge!(value)
          elsif MERGEABLE_LIST_ATTRIBUTES.include?(key)
            add_to_set(key, value)
          else
            @data[key] = value
          end
        end
        self
      end
      alias_method :add, :merge!

      def merge(other_data)
        dup.merge!(other_data)
      end

      def add_to_set(key, value)
        @data[key] ||= Set.new
        return unless value
        items_to_process = value.is_a?(Set) ? value.to_a : Array(value)
        items_to_process.each do |item|
          item.to_s.split.each do |token|
            @data[key].add(token) unless token.empty?
          end
        end
      end

      def remove(other_data)
        (other_data || {}).each do |key, _|
          @data.delete(key.to_sym)
        end
        self
      end

      def toggle(other_data)
        (other_data || {}).each do |key, value|
          key = key.to_sym
          @data[key] == value ? @data.delete(key) : @data[key] = value
        end
        self
      end

      def to_h
        flatten_data_hash(@data)
      end

      private

      def flatten_data_hash(hash, prefix = "data", accumulator = {})
        hash.each do |key, value|
          current_key = "#{prefix}-#{key.to_s.tr('_', '-')}"
          if key.to_s.end_with?("_value")
            serialized_value = case value
            when Hash, Array then value.to_json
            else value
            end
            accumulator[current_key] = serialized_value
          elsif value.is_a?(Hash)
            flatten_data_hash(value, current_key, accumulator)
          else
            serialized_value = value.is_a?(Set) ? value.to_a.join(" ") : value
            accumulator[current_key] = serialized_value unless serialized_value.to_s.empty?
          end
        end
        accumulator
      end
    end
  end
end
