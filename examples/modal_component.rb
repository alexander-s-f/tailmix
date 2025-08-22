# frozen_string_literal: true

require_relative "../lib/tailmix"

class ModalComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    element :base, "fixed inset-0 z-50 flex items-center justify-center" do
      dimension :open, default: true do
        option true, "visible opacity-100"
        option false, "invisible opacity-0"
      end
      stimulus.controller("modal")
    end

    element :overlay, "fixed inset-0 bg-black/50 transition-opacity" do
      stimulus.context("modal").action("click->modal#close")
    end

    element :panel, "relative bg-white rounded-lg shadow-xl transition-transform transform" do
      dimension :size, default: :md do
        option :sm, "w-full max-w-sm p-4"
        option :md, "w-full max-w-md p-6"
        option :lg, "w-full max-w-lg p-8"
      end
      stimulus.context("modal").target("panel")
    end

    element :title, "text-lg font-semibold text-gray-900"
    element :body, "mt-2 text-sm text-gray-600"
    element :close_button, "absolute top-2 right-2 p-1 text-gray-400 rounded-full hover:bg-gray-100 hover:text-gray-600" do
      stimulus.context("modal").action("click->modal#close")
    end

    element :footer, "mt-4 pt-4 border-t flex justify-end"
    element :confirm_button, "relative inline-flex items-center px-4 py-2 bg-blue-600 text-white font-semibold rounded-md hover:bg-blue-700" do
      stimulus.controller("form-submission")
              .action("click->form-submission#submit")
              .action_payload(:enter_pending_state, as: :pending_data)
    end

    element :spinner, "absolute inset-0 flex items-center justify-center hidden"

    action :lock, method: :add do
      element :close_button do
        classes "hidden"
      end
      element :panel do
        data locked: true, reason: "processing"
      end
    end

    action :enter_pending_state, method: :add do
      element :confirm_button do
        classes "opacity-75 cursor-not-allowed"
      end
      element :spinner do
        classes "flex"
      end
    end
  end

  def initialize(size: :md, open: false)
    @ui = tailmix(size: size, open: open)
  end

  def lock!
    @ui.action(:lock).apply!
  end
end
