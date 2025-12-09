# frozen_string_literal: true

module Tailmix
  module ViewHelpers
    def tailmix_include_tags
      html = []

      # html << javascript_include_tag("tailmix/index", type: "module", data: { turbo_track: "reload" })
      html << javascript_include_tag("tailmix/tailmix.bundle", defer: true, data: { turbo_track: "reload" })

      if Rails.env.development?
        version = Time.now.to_i
        definitions_url = tailmix.definitions_path(v: version)

        html << javascript_include_tag(definitions_url, defer: true, data: { turbo_track: "reload" })
      else
        html << javascript_include_tag("tailmix_definitions", defer: true, data: { turbo_track: "reload" })
      end

      safe_join(html, "\n")
    end
  end
end
