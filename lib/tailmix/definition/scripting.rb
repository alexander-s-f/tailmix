# frozen_string_literal: true

# This module will contain all the logic for the new S-expression based
# execution engine, including the interpreter, DSL builder, and more.

module Tailmix
  module Scripting
    class Error < StandardError; end
  end
end

require_relative "scripting/interpreter"
require_relative "scripting/builder"
