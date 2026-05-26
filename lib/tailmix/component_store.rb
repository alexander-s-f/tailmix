# frozen_string_literal: true

require "digest"
require "singleton"

module Tailmix
  class ComponentStore
    include Singleton

    def initialize
      @definitions = {}
      @version_hash = ""
    end

    def to_js
      refresh! if needs_refresh?
      generate_js_content
    end

    def write_to_disk!
      refresh!

      path = Rails.root.join("app/javascript/tailmix_definitions.js")

      File.open(path, "w") do |f|
        f.write(generate_js_content)
      end

      puts "[Tailmix] Wrote definitions to #{path} (Version: #{@version_hash[0..7]})"
    end

    def refresh!
      reload_components!

      new_definitions = {}
      ObjectSpace.each_object(Class) do |klass|
        # Skip singleton and anonymous classes (like a lot of Rails internals)
        next if klass.singleton_class?
        next if klass.name.nil?

        if klass.respond_to?(:tailmix_definition)
          definition = klass.tailmix_definition
          new_definitions[klass.name] = definition if definition
        end
      end

      @definitions = new_definitions.sort.to_h

      json_payload = @definitions.to_json
      @version_hash = Digest::MD5.hexdigest(json_payload)
    end

    def generate_js_content
      <<~JS
        // Tailmix Definitions. Version: #{@version_hash}
        (function() {
          var defs = #{@definitions.to_json};

          if (typeof window !== 'undefined') {
            window.Tailmix = window.Tailmix || {};
            window.Tailmix.definitions = window.Tailmix.definitions || {};
            Object.assign(window.Tailmix.definitions, defs);

            if (window.Tailmix.start) window.Tailmix.start();
          }
        })();
      JS
    end

    def version
      @version_hash
    end

    private

    def needs_refresh?
      return true if @version_hash.empty?
      return true if Rails.env.development?
      false
    end

    def reload_components!
      Rails.application.reloader.reload! if Rails.env.development?

      dirs = [ Rails.root.join("app/components"), Rails.root.join("app/views/components") ]
      dirs.select { |d| Dir.exist?(d) }.each do |dir|
        Dir[dir.join("**/*.rb")].each do |file|
          begin
            require_dependency file
          rescue LoadError, NameError
            # ignore
          end
        end
      end
    end
  end
end
