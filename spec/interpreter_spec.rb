# frozen_string_literal: true

require "spec_helper"
require "tailmix/scripting"

RSpec.describe Tailmix::Scripting::Interpreter do
  subject { described_class }

  describe ".eval_all" do
    it "handles an empty list of expressions" do
      initial_context = { a: 1 }
      final_context = subject.eval_all([], initial_context)
      expect(final_context).to eq({ a: 1 })
    end

    context "with state manipulation operations" do
      it "sets a value in the context" do
        expr = [ [ :set, :a, 10 ] ]
        final_context = subject.eval_all(expr, { a: 1 })
        expect(final_context[:a]).to eq(10)
      end

      it "toggles a boolean value from true to false" do
        expr = [ [ :toggle, :open ] ]
        final_context = subject.eval_all(expr, { open: true })
        expect(final_context[:open]).to be false
      end

      it "toggles a boolean value from false to true" do
        expr = [ [ :toggle, :open ] ]
        final_context = subject.eval_all(expr, { open: false })
        expect(final_context[:open]).to be true
      end

      it "increments a value" do
        expr = [ [ :increment, :counter ] ]
        final_context = subject.eval_all(expr, { counter: 5 })
        expect(final_context[:counter]).to eq(6)
      end

      it "increments a nil value starting from 0" do
        expr = [ [ :increment, :counter ] ]
        final_context = subject.eval_all(expr, {})
        expect(final_context[:counter]).to eq(1)
      end
    end

    context "with control flow" do
      it "executes the 'then' branch if condition is true" do
        expr = [
          [ :if, [ :eq, [ :state, :status ], "active" ],
           [ [ :set, :result, "was_active" ] ],
           [ [ :set, :result, "was_inactive" ] ] ]
        ]
        final_context = subject.eval_all(expr, { status: "active" })
        expect(final_context[:result]).to eq("was_active")
      end

      it "executes the 'else' branch if condition is false" do
        expr = [
          [ :if, [ :gt, [ :state, :counter ], 10 ],
           [ [ :set, :result, "too_high" ] ],
           [ [ :set, :result, "ok" ] ] ]
        ]
        final_context = subject.eval_all(expr, { counter: 5 })
        expect(final_context[:result]).to eq("ok")
      end

      it "handles nested expressions" do
        expr = [
          [ :set, :a, 5 ],
          [ :set, :b, 10 ],
          [ :if, [ :lt, [ :state, :a ], [ :state, :b ] ],
           [ [ :set, :result, "a_is_less" ] ] ]
        ]
        final_context = subject.eval_all(expr, {})
        expect(final_context[:result]).to eq("a_is_less")
      end
    end

    context "with collection operations" do
      it "pushes an element to an array" do
        expr = [ [ :array_push, :items, { id: 2 } ] ]
        final_context = subject.eval_all(expr, { items: [ { id: 1 } ] })
        expect(final_context[:items]).to eq([ { id: 1 }, { id: 2 } ])
      end

      it "pushes an element to a nil value" do
        expr = [ [ :array_push, :items, "hello" ] ]
        final_context = subject.eval_all(expr, {})
        expect(final_context[:items]).to eq([ "hello" ])
      end

      it "removes an element from an array by index" do
        expr = [ [ :array_remove_at, :items, 1 ] ]
        final_context = subject.eval_all(expr, { items: %w[a b c] })
        expect(final_context[:items]).to eq(%w[a c])
      end

      it "updates an element in an array by index" do
        expr = [ [ :array_update_at, :items, 0, "new" ] ]
        final_context = subject.eval_all(expr, { items: %w[a b c] })
        expect(final_context[:items]).to eq(%w[new b c])
      end
    end
  end
end
