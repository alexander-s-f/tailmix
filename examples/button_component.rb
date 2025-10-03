# frozen_string_literal: true

class ButtonComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :intent, default: :primary
    state :look, default: :fill

    element :button, "inline-flex font-semibold border rounded px-4 py-2" do
      # No more `state.` prefix, just direct variable access
      dimension on: state.intent do
        variant :primary, "bg-blue-500 text-white border-blue-500"
        variant :danger, "bg-red-500 text-white border-red-500"
      end

      dimension on: state.look do
        variant :fill, ""
        variant :outline, "bg-transparent"
      end

      # The `on:` hash now expects direct values, not expressions
      compound_variant on: { intent: :primary, look: :outline } do
        classes "text-blue-500"
      end

      compound_variant on: { intent: :danger, look: :outline } do
        classes "text-red-500"
      end
    end
  end

  def initialize(intent: :primary, look: :fill, id: nil)
    # Default for `look` should be provided in initialize for clarity
    # if it can be nil, otherwise the `dimension on: look` might get a nil value.
    @ui = tailmix(intent: intent, look: look, id: id)
  end
end
