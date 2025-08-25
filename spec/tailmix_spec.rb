# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe Tailmix do
  let(:base_component_class) do
    Class.new do
      include Tailmix
      tailmix do
        element :wrapper, "p-4"
        element :icon, "icon" do
          dimension :color, default: :gray do
            variant :gray, "text-gray-500"
            variant :red, "text-red-500"
          end
        end
        action :disable, method: :add do
          element :wrapper do
            classes "opacity-50"
          end
        end
      end

      def api_key; "API_KEY_FROM_METHOD"; end
    end
  end

  let(:child_component_class) do
    Class.new(base_component_class) do
      include Tailmix
      tailmix do
        element :wrapper, "rounded-lg"
        element :icon do
          dimension :color do
            variant :green, "text-green-500"
            variant :gray, "text-slate-600" do
              classes "dark:text-slate-400", group: :dark_mode
              data theme: "dark"
              aria hidden: "true"
            end
          end
          stimulus.controller("icon").value(:api_key, method: :api_key)
        end
        element :text, "font-bold"

        action :disable, method: :add do
          element :wrapper do
            classes "pointer-events-none"
            data disabled: true
          end
        end
      end

      attr_reader :ui

      def initialize(color: :gray)
        @ui = tailmix(color: color)
      end
    end
  end

  describe "DSL & Definition Merging" do
    let(:definition) { child_component_class.tailmix_definition }

    it "merges element classes from parent and child" do
      wrapper_classes = definition.elements[:wrapper].attributes.classes
      expect(wrapper_classes).to contain_exactly("p-4", "rounded-lg")
    end

    it "adds new elements defined in child" do
      expect(definition.elements.keys).to contain_exactly(:wrapper, :icon, :text)
    end

    it "merges dimensions, overriding parent variants" do
      color_dim = definition.elements[:icon].dimensions[:color]
      expect(color_dim[:variants].keys).to contain_exactly(:gray, :red, :green)
      expect(color_dim[:variants][:gray].classes).to include("text-slate-600")
    end

    it "overrides parent actions completely" do
      disable_action = definition.actions[:disable]
      mutations = disable_action.mutations[:wrapper]
      expect(mutations).to include({ field: :classes, method: :add, payload: "pointer-events-none" })
      expect(mutations).to include({ field: :data, method: :add, payload: { disabled: true } })
    end
  end

  describe "Runtime Behavior" do
    let(:component_instance) { child_component_class.new }
    let(:ui) { component_instance.ui }

    context "with default dimensions" do
      let(:component_instance) { child_component_class.new } # color: :gray is default
      let(:ui) { component_instance.ui }

      it "applies default values" do
        expect(ui.icon.to_s).to include("text-slate-600")
      end

      it "applies grouped classes from the variant" do
        expect(ui.icon.to_s).to include("dark:text-slate-400")
      end

      it "applies data attributes from the variant" do
        expect(ui.icon.to_h["data-theme"]).to eq("dark")
      end

      it "applies aria attributes from the variant" do
        expect(ui.icon.to_h["aria-hidden"]).to eq("true")
      end
    end

    context "with overridden red color" do
      let(:component_instance) { child_component_class.new(color: :red) }
      let(:ui) { component_instance.ui }

      it "applies the red color class" do
        expect(ui.icon.to_s).to include("text-red-500")
        # Ensure it doesn't have attributes from the gray variant
        expect(ui.icon.to_h).not_to have_key("data-theme")
        expect(ui.icon.to_h).not_to have_key("aria-hidden")
      end
    end

    describe "Stimulus Compiler with dynamic values" do
      it "compiles values resolved from component methods" do
        attributes = ui.icon.to_h
        expect(attributes["data-icon-api-key-value"]).to eq("API_KEY_FROM_METHOD")
      end
    end

    describe "Actions" do
      it "uses the overridden action definition" do
        ui.action(:disable).apply!

        attributes = ui.wrapper.to_h
        expect(attributes[:class]).to include("pointer-events-none")
        expect(attributes["data-disabled"]).to be true
        expect(attributes[:class]).not_to include("opacity-50")
      end
    end
  end
end
