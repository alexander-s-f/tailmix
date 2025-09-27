# frozen_string_literal: true

class ButtonComponent
  include Tailmix

  tailmix do
    plugin :auto_focus, on: :button, delay: 100

    state :intent, default: :primary
    state :look, default: :fill

    element :button, "inline-flex font-semibold border rounded px-4 py-2" do
      dimension :intent do
        variant :primary, "bg-blue-500 text-white border-blue-500"
        variant :danger, "bg-red-500 text-white border-red-500"
      end

      dimension :look do
        variant :fill, ""
        variant :outline, "bg-transparent"
      end

      compound_variant on: { intent: :primary, look: :outline } do
        classes "text-blue-500"
      end

      compound_variant on: { intent: :danger, look: :outline } do
        classes "text-red-500"
      end
    end
  end

  attr_reader :ui
  def initialize(intent: :primary, look: nil, id: nil)
    @ui = tailmix(intent: intent, look: look, id: id)
  end
end
