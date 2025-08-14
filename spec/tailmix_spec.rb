# frozen_string_literal: true

require "spec_helper"

RSpec.describe Tailmix do
  let(:test_component_class) do
    Class.new do
      include Tailmix

      tailmix do
        element :container, "w-full rounded-lg" do
          state do
            option :info, "bg-blue-50 text-blue-700", default: true
            option :success, "bg-green-50 text-green-700"
          end
          size do
            option :md, "p-4", default: true
            option :lg, "p-6"
          end
        end

        element :title, "font-bold" do
          state do
            option :info, "text-blue-900"
            option :success, "text-green-900"
          end
        end
      end

      attr_reader :classes

      def initialize(variants = {})
        # `tailmix` - наш приватный метод из миксина
        @classes = send(:tailmix, variants)
      end
    end
  end

  # --- Тесты ---

  describe "DSL Definition" do
    it "correctly parses the schema" do
      schema = test_component_class.tailmix_schema
      expect(schema).to be_a(Tailmix::Schema)
      expect(schema.elements.keys).to contain_exactly(:container, :title)
      expect(schema.elements[:container].dimensions[:state].options[:success]).to eq("bg-green-50 text-green-700")
      expect(schema.elements[:container].dimensions[:size].default_option).to eq(:md)
    end
  end

  describe "Resolver & Manager Initialization" do
    it "applies default variants correctly" do
      instance = test_component_class.new
      expect(instance.classes.container.to_s).to eq("w-full rounded-lg bg-blue-50 text-blue-700 p-4")
      expect(instance.classes.title.to_s).to eq("font-bold text-blue-900") # `state` применился, т.к. есть дефолт
    end

    it "applies explicit variants" do
      instance = test_component_class.new(state: :success, size: :lg)
      expect(instance.classes.container.to_s).to eq("w-full rounded-lg bg-green-50 text-green-700 p-6")
      expect(instance.classes.title.to_s).to eq("font-bold text-green-900")
    end

    it "mixes explicit and default variants" do
      instance = test_component_class.new(state: :success)
      # `state` переопределен, `size` взят по умолчанию
      expect(instance.classes.container.to_s).to eq("w-full rounded-lg bg-green-50 text-green-700 p-4")
    end
  end

  describe "Dynamic & Imperative API" do
    let(:instance) { test_component_class.new }

    it "updates classes after `combine` is called" do
      # Начальное состояние (дефолтное)
      expect(instance.classes.container.to_s).to include("bg-blue-50")

      # Меняем состояние
      instance.classes.combine(state: :success)

      # Проверяем, что классы обновились
      expect(instance.classes.container.to_s).to include("bg-green-50")
      expect(instance.classes.container.to_s).not_to include("bg-blue-50")
    end

    it "imperatively adds classes with `add`" do
      initial_classes = instance.classes.container.to_s
      instance.classes.container.add("animate-pulse", "shadow-lg")

      expect(instance.classes.container.to_s).to eq("#{initial_classes} animate-pulse shadow-lg")
    end

    it "imperatively removes classes with `remove`" do
      instance.classes.container.remove("rounded-lg")
      expect(instance.classes.container.to_s).not_to include("rounded-lg")
    end

    it "imperatively toggles classes with `toggle`" do
      # Сначала класса нет, `toggle` его добавит
      instance.classes.container.toggle("is-active")
      expect(instance.classes.container.to_s).to include("is-active")

      # Теперь класс есть, `toggle` его удалит
      instance.classes.container.toggle("is-active")
      expect(instance.classes.container.to_s).not_to include("is-active")
    end
  end
end
