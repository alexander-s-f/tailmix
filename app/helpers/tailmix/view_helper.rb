# frozen_string_literal: true

module Tailmix
  module ViewHelper
    def tailmix_definitions_tag
      definitions = Tailmix::Registry.instance.definitions
      return if definitions.empty?

      payload = { components: definitions }

      tag.script(type: "application/json", "data-tailmix-definitions": true) do
        payload.to_json.html_safe
      end
    end

    def tailmix_tags
      proxy =
        if respond_to?(:tailmix)
          tailmix
        else
          Rails.application.routes.url_helpers.tailmix
        end

      path = proxy.definitions_path  # => "/tailmix/definitions"

      version =
        if Rails.env.development?
          Time.now.to_i
        else
          store = Tailmix::ComponentStore.instance
          store.refresh! if store.version.empty?
          store.version
        end

      javascript_include_tag("#{path}.js?v=#{version}", defer: true, data: { turbo_track: "reload" })
      # tag.script(src: "#{path}.js?v=#{version}", defer: true, data: { turbo_track: "reload" })
    end
  end
end
