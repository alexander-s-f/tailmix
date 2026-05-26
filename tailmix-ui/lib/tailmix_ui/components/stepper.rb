# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix-powered state container for stage pipeline Steppers.
    class StepperState
      include Tailmix

      tailmix do
        state :current_step, default: 1

        element :root, "flex flex-col md:flex-row items-stretch justify-between w-full border border-gray-800 bg-gray-900/50 rounded-xl p-4 gap-4"

        element :step_item, "flex-1 flex items-center p-3 rounded-lg border font-medium text-sm transition-all duration-200" do
          # Completed State (greater than step parameter)
          style condition: state.current_step > param.step do
            classes "border-green-800/80 bg-green-950/20 text-green-400"
          end
          # Active State (equal to step parameter)
          style condition: state.current_step == param.step do
            classes "border-blue-600/80 bg-blue-950/30 text-blue-200 ring-1 ring-blue-500/50"
          end
          # Upcoming State (less than step parameter)
          style condition: state.current_step < param.step do
            classes "border-gray-800 bg-gray-950/20 text-gray-500"
          end
        end

        element :prev_btn, "px-3 py-1.5 rounded-lg text-sm font-medium border border-gray-800 bg-gray-900 text-white hover:bg-gray-800 transition-all cursor-pointer" do
          on :click do
            set state.current_step, state.current_step - 1
          end
          style condition: state.current_step <= 1 do
            prop disabled: true
            classes "opacity-40 cursor-not-allowed pointer-events-none"
          end
        end

        element :next_btn, "px-3 py-1.5 rounded-lg text-sm font-medium border border-gray-800 bg-gray-900 text-white hover:bg-gray-800 transition-all cursor-pointer" do
          on :click do
            set state.current_step, state.current_step + 1
          end
          style condition: state.current_step >= param.max_steps do
            prop disabled: true
            classes "opacity-40 cursor-not-allowed pointer-events-none"
          end
        end
      end

      def initialize(current_step: 1)
        @ui = tailmix(current_step: current_step)
      end
      attr_reader :ui
    end

    # The Arbre component for rendering interactive pipeline steps.
    class Stepper < BaseComponent
      def build(options = {})
        current_step = options.delete(:current_step) || 1
        @max_steps = options.delete(:max_steps) || 3
        classes = options.delete(:class)

        @tailmix_ui = @stepper_ui = StepperState.new(current_step: current_step).ui

        super(@stepper_ui.root(options))
        add_class(classes) if classes

        set_attribute "data-tailmix-component", StepperState.name
        set_attribute "data-tailmix-state", @stepper_ui.state_json

        div class: "flex items-center gap-4 w-full" do
          @steps_target = current_arbre_element
        end
      end

      # Stepper step item
      def step(step_num, label, options = {})
        @steps_target << div(@stepper_ui.step_item(step: step_num, **options)) do
          # Render step circle badge
          span class: "w-6 h-6 rounded-full flex items-center justify-center mr-2 border border-current text-xs font-bold" do
            text_node step_num.to_s
          end
          span label.to_s
        end
      end

      # Controls layout container keeping lexical block evaluation context
      def controls(options = {}, &block)
        classes = options.delete(:class)
        stepper_instance = self
        div({
          class: "flex justify-between items-center mt-6 pt-4 border-t border-gray-800 w-full"
        }.merge(options)) do
          add_class(classes) if classes
          if block
            stepper_instance.instance_eval(&block)
          end
        end
      end

      # Step backward toggle action
      def prev_button(label = "Back", options = {})
        button @stepper_ui.prev_btn(options) do
          text_node label
        end
      end

      # Step forward toggle action
      def next_button(label = "Next", options = {})
        button @stepper_ui.next_btn(max_steps: @max_steps, **options) do
          text_node label
        end
      end
    end
  end
end
