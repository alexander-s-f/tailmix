require_relative "../lib/tailmix"

class CardComponent
  include Tailmix

  tailmix do
    element :wrapper, "rounded-lg shadow-md transition-all"
    element :title, "font-bold text-lg text-gray-800"

    action :highlight, method: :toggle do
      element :wrapper, "shadow-xl ring-2 ring-blue-500"
      element :title, "text-blue-600"
    end

    action :archive, method: :add do
      element :wrapper, "opacity-50 bg-gray-100"
    end
  end
end

card = CardComponent.new
ui = card.tailmix

puts "Initial state:"
puts "Wrapper: #{ui.wrapper}" # => "rounded-lg shadow-md transition-all"
puts "Title:   #{ui.title}"   # => "font-bold text-lg text-gray-800"
puts "---"

# action :highlight
ui.action(:highlight).apply!

puts "After highlight:"
puts "Wrapper: #{ui.wrapper}" # => "rounded-lg shadow-md transition-all shadow-xl ring-2 ring-blue-500"
puts "Title:   #{ui.title}"   # => "font-bold text-lg text-gray-800 text-blue-600"
puts "---"

ui.action(:highlight).apply!

puts "After second highlight (toggled off):"
puts "Wrapper: #{ui.wrapper}" # => "rounded-lg shadow-md transition-all"
puts "Title:   #{ui.title}"   # => "font-bold text-lg text-gray-800"
puts "---"

# action :archive
ui.action(:archive).apply!

puts "After archive:"
puts "Wrapper: #{ui.wrapper}" # => "rounded-lg shadow-md transition-all opacity-50 bg-gray-100"
puts "Title:   #{ui.title}"   # => "font-bold text-lg text-gray-800"

puts ui.wrapper.to_h # => {"class"=>"rounded-lg shadow-md transition-all opacity-50 bg-gray-100"}

puts "-" * 80
puts "action archive:"
puts ui.action(:archive).to_h
puts ui.action(:archive).data

puts "definitions:"
puts ui.definition.to_h
puts ui.definition.to_json

puts "action controller stimulus:"
puts ui.action(:archive).stimulus("card")
