# frozen_string_literal: true

class SyncInputComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :value, default: ""

    element :container, "p-4 border border-dashed border-yellow-500"
    element :label, "block text-xl mb-4 min-h-[2em] text-yellow-500" do
      bind :text, to: :value
    end
    element :input, "border text-sm rounded-lg block w-full p-2.5 bg-gray-700" do
      type "text"
      placeholder "Type something here..."

      model this.value, to: state.value
    end
  end

  def initialize
    @ui = tailmix
  end
end
