# frozen_string_literal: true

require "arbre"
require "active_support/all"
require "tailmix"

require_relative "tailmix_ui/version"
require_relative "tailmix_ui/configuration"
require_relative "tailmix_ui/base_component"

require_relative "tailmix_ui/components/button"
require_relative "tailmix_ui/components/badge"
require_relative "tailmix_ui/components/card"
require_relative "tailmix_ui/components/tabs"
require_relative "tailmix_ui/components/modal"

module TailmixUi
  class Error < StandardError; end
end
