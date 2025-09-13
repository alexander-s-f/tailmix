# frozen_string_literal: true

require_relative "../lib/tailmix"
require_relative "helpers"

class UserCart
  # include Tailmix::Service ?
end

class ModalComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    plugin :auto_focus, on: :open_button, delay: 100
    state :open, default: false, toggle: true
    state :user_id, default: nil
    state :user_name, default: nil
    state :user_email, default: nil
    state :value, default: ""
    state :text, default: ""
    state :counter, default: 0
    state :status_text, default: "Ready"

    # --- Macros ---
    macro :update_status, :text do |text|
      set(:status_text, text)
      log("Status updated to:", text)
    end

    # --- Actions ---

    action :report do
      if?(state(:counter).gt(5)) do
        expand_macro(:update_status, concat("Counter is high: ", state(:counter)))
      end
    end

    action :increment_and_report do
      increment(:counter)
      expand_macro(:update_status, concat("Counter is high: ", state(:counter)))
      call(:report)
    end

    action :reset do
      set(:counter, 0)
      expand_macro(:update_status, "Counter has been reset.")
    end

    # --- Reactions ---
    reaction on: :open do
      if?(state(:open)) do
        expand_macro(:update_status, "Modal opened.")
      end
      log("user_id:", state(:user_id))
      fetch("/user.json", params: { user_id: state(:user_id) }, service: UserCart) do |response|
        if?(response.success?) do
          log("result:", response.result)
          log("result(:name):", response.result(:name))
          set(:user_name, response.result(:name))
          set(:user_email, response.result(:email))
        end
      end
    end

    element :container do
    end

    element :reset_button do
      on :click, :reset
    end

    element :increment_button do
      on :click, :increment_and_report
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

    element :counter, "text-xl p-4 min-h-[2em]" do
      bind :text, to: :counter
    end

    element :text, "text-xl p-4 min-h-[2em]" do
      bind :text, to: :text
    end

    element :user_name, "text-xl p-4 min-h-[2em]" do
      bind :text, to: :user_name
    end

    element :user_email, "text-xl p-4 min-h-[2em]" do
      bind :text, to: :user_email
    end

    element :close_button, "absolute top-2 right-2 p-1 text-gray-500 rounded-full cursor-pointer" do
      on :click, :toggle_open
    end

    element :title, "text-lg font-semibold p-4 border-gray-600"
    element :body, "p-4"
  end

  def initialize(open: false, user_id: nil, id: nil)
    @ui = tailmix(open: open, user_id: user_id, id: id)
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
