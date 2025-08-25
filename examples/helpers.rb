# frozen_string_literal: true

def stringify_keys(obj)
  case obj
  when Hash
    obj.transform_keys(&:to_s).transform_values { |v| stringify_keys(v) }
  when Array
    obj.map { |v| stringify_keys(v) }
  else
    obj
  end
end

def print_component_ui(component_instance)
  component_instance.class.dev.elements.each do |element_name|
    element = component_instance.ui.send(element_name)
    puts element_name
    element.each_attribute do |attribute|
      attribute.each do |key, value|
        puts "    #{key} :-> #{value}"
      end
      puts ""
    end
  end
end