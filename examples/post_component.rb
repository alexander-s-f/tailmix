require_relative "../lib/tailmix"

class PostComponent
  include Tailmix

  tailmix do
    element :panel, "p-4" do
      size do
        option :sm, "p-2"
        option :md, "p-4", default: true
        option :lg, "p-8"
      end
      active do
        option true, "block"
        option false, "hidden", default: true
      end
    end
  end
end


component = PostComponent.new

ui = component.tailmix
puts "Default: #{ui.panel}" # => "p-4 hidden"

ui_active_large = component.tailmix(active: true, size: :lg)
puts "Active & Large: #{ui_active_large.panel}" # => "p-8 block"

ui.panel.add("border rounded-lg")
puts "With border: #{ui.panel}" # => "p-4 hidden border rounded-lg"

ui.panel.toggle("hidden bg-gray-100")
puts "Toggled: #{ui.panel}" # => "p-4 border rounded-lg bg-gray-100"

ui.panel.toggle("hidden bg-gray-100")
puts "Toggled: #{ui.panel}" # => "p-4 border rounded-lg hidden"
