# frozen_string_literal: true

module Tailmix
  class Manifest

    def self.compile!
      puts "[Tailmix] Compiling component definitions..."

      output_path = Rails.root.join("app/javascript/tailmix_definitions.js")

      Rails.application.eager_load!

      definitions = {}
      ObjectSpace.each_object(Class) do |klass|
        # Skip singleton and anonymous classes (like a lot of Rails internals)
        next if klass.singleton_class?
        next if klass.name.nil?

        if klass.respond_to?(:tailmix_definition)
          definitions[klass.name] = klass.tailmix_definition
        end
      end

      js_content = <<~JS
        (function() {
          window.Tailmix = window.Tailmix || {};
          window.Tailmix.definitions = window.Tailmix.definitions || {};

          var newDefinitions = #{definitions.to_json};

          Object.assign(window.Tailmix.definitions, newDefinitions);
        })();
      JS

      File.write(output_path, js_content)
      puts "[Tailmix] Wrote #{definitions.size} definitions to #{output_path}"
    end
  end
end
