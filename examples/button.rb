# frozen_string_literal: true

require_relative "../lib/tailmix"
require_relative "helpers"

class Button
  include Tailmix

  tailmix do
    element :button do
      dimension :intent, default: :primary do
        variant :primary, "bg-blue-500"
        variant :danger, "bg-red-500"
      end

      dimension :size, default: :medium do
        variant :medium, "p-4"
        variant :small, "p-2"
      end

      compound_variant on: { intent: :danger, size: :small } do
        classes "font-bold"
        data special: "true"
      end
    end
  end

  attr_reader :ui
  def initialize(intent: :primary, size: :medium)
    @ui = tailmix(intent: intent, size: size)
  end
end


puts "-" * 100
puts Button.dev.docs

# == Tailmix Docs for Button ==
# Signature: `initialize(intent: :primary, size: :medium)`
#
# Dimensions:
#   - intent (default: :primary)
#     - :primary:
#       - classes : "bg-blue-500"
#     - :danger:
#       - classes : "bg-red-500"
#   - size (default: :medium)
#     - :medium:
#       - classes : "p-4"
#     - :small:
#       - classes : "p-2"
#
# Compound Variants:
#   - on element `:button`:
#     - on: { intent: :danger, size: :small }
#       - classes : "font-bold"
#       - data: {:special=>"true"}
#
# No actions defined.
#
# button
#     classes :-> bg-red-500 p-4
#     data :-> {}
#     aria :-> {}
#     tailmix :-> {"data-tailmix-button"=>"intent:danger,size:medium"}

not_compound_component = Button.new(intent: :danger, size: :medium)
print_component_ui(not_compound_component)
# button
#     classes :-> bg-red-500 p-4
#     data :-> {}
#     aria :-> {}
#     tailmix :-> {"data-tailmix-button"=>"intent:danger,size:medium"}

compound_component = Button.new(intent: :danger, size: :small)
print_component_ui(compound_component)
# button
#     classes :-> bg-red-500 p-2 font-bold
#     data :-> {"data-special"=>"true"}
#     aria :-> {}
#     tailmix :-> {"data-tailmix-button"=>"intent:danger,size:small"}
