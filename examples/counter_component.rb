# frozen_string_literal: true

class CounterComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :count, default: 0

    element :container, "p-4"
    element :increment_button, "text-xl text-yellow-500 cursor-pointer" do
      constructor do |param|
        on :click do
          state.count.increment
          log(param) # >> {test: 123}
        end
      end
    end

    element :label, "text-xl p-4 min-h-[2em]" do
      bind :text, to: :count
    end
  end

  def initialize
    @ui = tailmix
  end
end
