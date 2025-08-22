# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe Tailmix do
  let(:modal_component_class) do
    Class.new do
      include Tailmix

      tailmix do
        # Elements
        element :base, "fixed inset-0" do
          dimension :open, default: false do
            option true, "visible"
            option false, "invisible"
          end
          stimulus.controller("modal")
        end

        element :panel, "p-6" do
          dimension :size, default: :md do
            option :sm, "max-w-sm"
            option :md, "max-w-md"
          end
        end

        element :confirm_button do
          stimulus.controller("form-submission").action("click->form-submission#submit")
                  .action_payload(:show_pending_state, as: :pending_data)
        end

        # Actions
        action :show_pending_state, method: :add do
          element :confirm_button do
            classes "is-loading"
            data pending: true
          end
        end

        action :show_pending_state, method: :add do
          element :confirm_button do
            classes "is-init", method: :add
            classes "is-loading", method: :toggle
            data pending: true, method: :toggle
            data init: true, method: :add
          end
        end
      end

      attr_reader :ui

      def initialize(open: false, size: :md)
        @ui = tailmix(open: open, size: size)
      end
    end
  end
end
