# frozen_string_literal: true

class StepperPreview < Lookbook::Preview
  # @param current_step select { choices: [1, 2, 3] } "Active step selection"
  def standard(current_step: 1)
    html = Arbre::Context.new do
      div class: "max-w-3xl mx-auto space-y-6 p-6 bg-gray-900/20 rounded-2xl border border-gray-800" do
        h3 "Interactive Deal Stages Stepper", class: "text-lg font-bold text-white mb-4"

        # The interactive Stepper layout
        stepper id: "stepper-demo", current_step: current_step.to_i, max_steps: 3 do
          step(1, "Lead Qualified")
          step(2, "Proposal Sent")
          step(3, "Deal Closed")

          controls do
            prev_button "Previous Stage", data: { action: "click->stepper-demo#prev" }
            next_button "Next Stage", data: { action: "click->stepper-demo#next" }
          end
        end
      end
    end.to_s
    render(PreviewWrapperComponent.new(html))
  end
end
