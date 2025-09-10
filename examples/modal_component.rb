# frozen_string_literal: true

require_relative "../lib/tailmix"
require_relative "helpers"

class ModalComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    plugin :auto_focus, on: :open_button, delay: 100
    state :open, default: false, toggle: true
    state :value, default: ""
    state :text, default: ""

    react on: :value do |r|
      # TODO: new dsl & interpreter
    end

    element :container do
    end

    element :open_button do
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

    element :panel, "relative bg-gray-800 text-gray-200 rounded-lg shadow-xl" do
      dimension :open do
        variant true, "block"
        variant false, "hidden"
      end
    end

    element :input, "border text-sm rounded-lg block w-full p-2.5 bg-gray-700" do
      type "text"
      placeholder "Type something here..."

      model :value, to: :value
    end

    element :result, "text-xl p-4 min-h-[2em]" do
      bind :text, to: :value
    end

    element :text, "text-xl p-4 min-h-[2em]" do
      bind :text, to: :text
    end

    element :close_button, "absolute top-2 right-2 p-1 text-gray-500 rounded-full cursor-pointer" do
      on :click, :toggle_open
    end

    element :title, "text-lg font-semibold p-4 border-gray-600"
    element :body, "p-4"
  end

  def initialize(open: false, id: nil)
    @ui = tailmix(open: open, id: id)
  end
end


modal = ModalComponent.new(open: false, id: :user_profile_modal)
ui = modal.ui


# puts "Definition:"
# puts JSON.pretty_generate(stringify_keys(ModalComponent.tailmix_definition.to_h))
puts "-" * 100
puts ModalComponent.dev.docs
puts "-" * 100

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
