# frozen_string_literal: true

class SyncInputComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :value, default: ""
    state :type, default: "text"
    state :types, default: %w[text password email number]

    element :container, "p-4 border border-dashed border-yellow-500"
    element :label, "block text-xl mb-4 min-h-[2em] text-yellow-500" do
      # Clearly binding element's `text` to component's `state.value`
      bind :text, to: state.value
    end

    element :input, "border text-sm rounded-lg block w-full p-2.5 bg-gray-700" do
      # Static attributes are set directly
      placeholder "Type something here..."

      # Two-way binding: element's `value` property is bound to `state.value`
      model this.value, to: state.value

      # One-way binding: element's `type` attribute is bound to `state.type`
      bind this.type, to: state.type
    end

    element :type_selector, "mt-4 border text-sm rounded-lg block w-full p-2.5 bg-gray-700" do
      # Two-way binding for the select dropdown
      model this.value, to: state.type
    end

    element :button, "mt-4 text-xl text-yellow-500 cursor-pointer" do
      on :click do
        # Action logic is now explicit and easy to read
        set(state.type, "password")
      end
    end
  end

  def initialize
    @ui = tailmix(type: "text", value: "Initial value")
  end
end
