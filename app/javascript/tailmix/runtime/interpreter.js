/**
 * The Interpreter is responsible for evaluating S-expressions on the client-side.
 * It takes an array of expressions and a context (component, event, etc.) and
 * executes the operations, primarily by updating the component's state.
 */
export class Interpreter {
    /**
     * @param {import('./component').Component} component The component instance.
     */
    constructor(component) {
        this.component = component;
    }

    /**
     * Evaluates a list of S-expressions in the context of the component.
     * @param {Array<Array<any>>} expressions An array of S-expressions.
     * @param {Event} [event=null] The DOM event that triggered the evaluation.
     */
    run(expressions, event = null) {
        // The `eval` method will now read fresh state directly from the component.
        const context = {
            event: event,
        };

        for (const expr of expressions) {
            this.eval(expr, context);
        }
    }

    /**
     * Evaluates a single S-expression recursively.
     * @param {any} expression The expression or literal to evaluate.
     * @param {object} context The current execution context.
     * @returns {any} The result of the evaluation.
     */
    eval(expression, context) {
        if (!Array.isArray(expression)) {
            return expression; // It's a literal value
        }
        if (expression.length === 0) {
            return null;
        }

        const [op, ...args] = expression;

        switch (op) {
            // Action Invocation
            case 'call': {
                const [actionName] = args;
                // We use the component's public API to run the other action
                this.component.api.runAction(actionName);
                return;
            }
            // State Manipulation
            case 'set': {
                const [key, value] = args;
                this.component.update({ [key]: this.eval(value, context) });
                return;
            }
            case 'toggle': {
                const [key] = args;
                this.component.update({ [key]: !this.component.state[key] });
                return;
            }
            case 'increment': {
                const [key, by = 1] = args;
                const currentValue = this.component.state[key] || 0;
                this.component.update({ [key]: currentValue + this.eval(by, context) });
                return;
            }

            // Control Flow
            case 'if': {
                const [condition, thenBranch, elseBranch] = args;
                if (this.eval(condition, context)) {
                    this.evalBranch(thenBranch, context);
                } else if (elseBranch) {
                    this.evalBranch(elseBranch, context);
                }
                return;
            }

            // Value Retrieval & Comparison
            case 'state':
                return this.component.state[args[0]];
            case 'event': // Allows access to event properties, e.g., ['event', 'target.value']
                return args[0].split('.').reduce((obj, key) => obj?.[key], context.event);
            case 'eq':
                return this.eval(args[0], context) === this.eval(args[1], context);
            case 'lt':
                return this.eval(args[0], context) < this.eval(args[1], context);
            case 'gt':
                return this.eval(args[0], context) > this.eval(args[1], context);
            case 'concat':
                return args.map(arg => this.eval(arg, context)).join('');
            // Debugging
            case 'log': {
                const resolvedArgs = args.map(arg => this.eval(arg, context));
                console.log('[Tailmix Interpreter Log]', ...resolvedArgs);
                return;
            }
            default:
                console.warn(`Tailmix: Unknown operation "${op}"`);
        }
    }

    /**
     * @private
     */
    evalBranch(branch, context) {
        if (!branch) return;
        for (const expr of branch) {
            this.eval(expr, context);
        }
    }
}
