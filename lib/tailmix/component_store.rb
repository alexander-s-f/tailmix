# frozen_string_literal: true

require "digest"

module Tailmix
  class ComponentStore
    include Singleton

    def initialize
      @definitions = {}
      @version_hash = ""
    end

    def refresh!
      reload_components!

      new_definitions = {}
      ObjectSpace.each_object(Class) do |klass|
        if klass.respond_to?(:tailmix_definition)
          new_definitions[klass.name] = klass.tailmix_definition
        end
      end

      @definitions = new_definitions.sort.to_h

      json_payload = @definitions.to_json
      @version_hash = Digest::MD5.hexdigest(json_payload)
    end

    def to_js
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
