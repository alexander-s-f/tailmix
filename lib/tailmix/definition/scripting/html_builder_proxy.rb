# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # DSL helper for building an S-expression that describes HTML.
      class HtmlBuilderProxy
        HTML_TAGS = %i[li div span button ul p a h1 h2 h3].to_set.freeze

        def initialize(builder)
          @builder = builder
        end

        # `method_missing` для всех тегов (li, div, и т.д.)
        def method_missing(tag_name, *args)
          return super unless HTML_TAGS.include?(tag_name)

          attributes = args.find { |arg| arg.is_a?(Hash) } || {}

          # All other arguments are considered child elements/content.
          children_and_content = args.reject { |arg| arg.is_a?(Hash) }

          resolved_children = @builder.resolve_expressions(children_and_content)
          resolved_attributes = @builder.resolve_expressions(attributes)

          [:html_build, tag_name, resolved_attributes, resolved_children]
        end

        def respond_to_missing?(method_name, include_private = false)
          HTML_TAGS.include?(method_name) || super
        end
      end
    end
  end
end
