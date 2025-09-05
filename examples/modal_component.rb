# frozen_string_literal: true

require_relative "../lib/tailmix"
require_relative "helpers"

class ModalComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    # --- State and Elements ---

    element :container do
      # We define the state :open.  The initial value is `false`.
      # The `:toggle` modifier automatically creates the `toggle_open` action for us.
      state :open, default: false, toggle: true
    end

    element :open_button do
      # We attach the `click` event to our auto-generated action.
      on :click, :toggle_open
    end

    element :base do
      dimension :open do
        variant true, "fixed inset-0 z-50 flex items-center justify-center visible opacity-100 transition-opacity"
        variant false, "invisible opacity-0"
      end
    end

    element :overlay do
      dimension :open do
        variant true, "fixed inset-0 bg-black/50"
        variant false, "hidden"
      end
      on :click, :toggle_open
    end

    element :panel, "relative bg-white rounded-lg shadow-xl" do
      dimension :open do
        variant true, "block"
        variant false, "hidden"
      end
    end

    element :close_button, "absolute top-2 right-2 p-1 text-gray-500 rounded-full cursor-pointer" do
      on :click, :toggle_open
    end

    element :title, "text-lg font-semibold text-gray-900 p-4 border-b"
    element :body, "p-4 text-gray-900"
  end

  def initialize(open: false, id: nil)
    @ui = tailmix(open: open, id: id)
  end
end


puts "-" * 100
puts ModalComponent.dev.docs
# puts ""

modal = ModalComponent.new(open: false, id: :user_profile_modal)
ui = modal.ui


# puts "Definition:"
# puts JSON.pretty_generate(stringify_keys(ModalComponent.tailmix_definition.to_h))

ModalComponent.dev.elements.each do |element_name|
  element = ui.send(element_name)
  puts element_name
  element.each_attribute do |attribute|
    attribute.each do |key, value|
      puts "    #{key} :-> #{value}"
    end
    puts ""
  end
end
