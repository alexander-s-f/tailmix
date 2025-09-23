# frozen_string_literal: true

require "cgi"

module Tailmix
  module Definition
    module Scripting
      module Operations
        module Html
          extend self

          # :element_attrs makes no sense on the server detached from the component.
          # Therefore, we will simply return `with` hash as regular attributes.
          def element_attrs(interpreter, args)
            _element_name, with_data = args
            interpreter.eval(with_data)
          end

          # Recursively builds an HTML string from an S-expression
          def html_build(interpreter, args)
            tag_name, attributes_expr, children_exprs = args

            # Calculating attributes
            attributes = interpreter.eval(attributes_expr)
            attrs_string = attributes.map { |k, v| " #{k}=\"#{CGI.escapeHTML(v.to_s)}\"" }.join

            # Calculating child elements
            children_html = Array(children_exprs).map { |expr| interpreter.eval(expr) }.join

            "<#{tag_name}#{attrs_string}>#{children_html}</#{tag_name}>"
          end
        end
      end
    end
  end
end
