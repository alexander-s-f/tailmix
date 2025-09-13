import { StateOperations } from './operations/state';
import { CollectionsOperations } from './operations/collections';
import { LogicalOperations } from './operations/logical';
import { InteropOperations } from './operations/interop';
import { HttpOperations } from './operations/http';
import { ArithmeticOperations } from './operations/arithmetic';
import { ValueOperations } from './operations/value';
import { ComparisonOperations } from './operations/comparison';

const OPERATIONS = {
    ...StateOperations,
    ...CollectionsOperations,
    ...LogicalOperations,
    ...InteropOperations,
    ...HttpOperations,
    ...ArithmeticOperations,
    ...ValueOperations,
    ...ComparisonOperations,
};

export class Interpreter {
    constructor(component) {
        this.component = component;
        this._responseContext = null;
    }

    async run(expressions, context = {}) {
        if (!Array.isArray(expressions)) {
            console.error("Tailmix Interpreter Error: `run` was called with a non-array value.", expressions);
            return;
        }

        for (const expr of expressions) {
            await this.eval(expr, context);
        }
    }

    async eval(expression, context) {
        if (!Array.isArray(expression)) {
            return expression;
        }

        if (expression.length === 0) {
            return null;
        }

        const [op, ...args] = expression;

        if (op === 'response') {
            if (!this._responseContext) {
                console.warn("Tailmix: `:response` can only be used inside a `fetch` callback.");
                return null;
            }
            // The `response` operation ALWAYS reads from the temporary response context.
            return args.reduce((obj, key) => obj?.[key], this._responseContext);
        }

        const handler = OPERATIONS[op];
        if (!handler) {
            console.warn(`Tailmix: Unknown operation "${op}"`);
            return;
        }

        // Call the handler, passing the interpreter instance, args, and the current context.
        return await handler(this, args, context);
    }

    async evalBranch(branch, context) {
        if (!branch) return;
        for (const expr of branch) {
            await this.eval(expr, context);
        }
    }
}
