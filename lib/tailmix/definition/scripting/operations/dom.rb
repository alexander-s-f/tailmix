# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      module Operations
        # On the server, DOM operations do nothing.
        # They exist so that the DSL does not break during server-side execution.
        module Dom
          extend self

          def dom_append(_interpreter, _args); end
          def dom_prepend(_interpreter, _args); end
          def dom_replace(_interpreter, _args); end
          def dom_remove(_interpreter, _args); end
          def dom_add_class(_interpreter, _args); end
          def dom_remove_class(_interpreter, _args); end
          def dom_toggle_class(_interpreter, _args); end
          def dom_set_attribute(_interpreter, _args); end
          def dom_set_value(_interpreter, _args); end
        end
      end
    end
  end
end
