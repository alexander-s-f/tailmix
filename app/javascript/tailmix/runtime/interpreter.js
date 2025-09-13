// app/javascript/tailmix/runtime/interpreter.js

export class Interpreter {
    constructor(component) {
        this.component = component;
    }

    async run(expressions, event = null) {
        const context = { event: event };
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
                this.component.update({ [key]: await this.eval(value, context) });
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
                this.component.update({ [key]: currentValue + (await this.eval(by, context)) });
                return;
            }

            // Collection Manipulation
            case 'array_push': {
                const [key, value] = args;
                const currentArray = this.component.state[key] || [];
                const newValue = await this.eval(value, context);
                this.component.update({ [key]: [...currentArray, newValue] });
                return;
            }
            case 'array_remove_at': {
                const [key, index] = args;
                const currentArray = this.component.state[key] || [];
                const resolvedIndex = await this.eval(index, context);
                const newArray = currentArray.filter((_, i) => i !== resolvedIndex);
                this.component.update({ [key]: newArray });
                return;
            }
            case 'array_update_at': {
                const [key, index, value] = args;
                const currentArray = this.component.state[key] || [];
                const resolvedIndex = await this.eval(index, context);
                const newValue = await this.eval(value, context);
                const newArray = currentArray.map((item, i) => (i === resolvedIndex ? newValue : item));
                this.component.update({ [key]: newArray });
                return;
            }

            // Control Flow
            case 'if': {
                const [condition, thenBranch, elseBranch] = args;
                if (await this.eval(condition, context)) {
                    await this.evalBranch(thenBranch, context);
                } else if (elseBranch) {
                    await this.evalBranch(elseBranch, context);
                }
                return;
            }

            // Server Interaction
            case 'fetch': {
                const [url, options = {}] = args;
                const { then: thenAction, catch: catchAction, params = {} } = options;
                const urlWithParams = new URL(url, window.location.origin);

                // Await parameter resolution before fetching
                for (const [key, value] of Object.entries(params)) {
                    urlWithParams.searchParams.append(key, await this.eval(value, context));
                }

                try {
                    const response = await fetch(urlWithParams.toString());
                    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                    const data = await response.json();
                    if (thenAction) this.component.api.runAction(thenAction, { payload: data });
                } catch (error) {
                    console.error("Tailmix fetch error:", error);
                    if (catchAction) this.component.api.runAction(catchAction, { payload: { message: error.message } });
                }
                return;
            }

            // Value Retrieval
            case 'state': return this.component.state[args[0]];
            case 'event': return args[0].split('.').reduce((obj, key) => obj?.[key], context.event);
            case 'now': return new Date().toISOString();

            // Value Computation
            case 'concat': {
                const resolvedArgs = await Promise.all(args.map(arg => this.eval(arg, context)));
                return resolvedArgs.join('');
            }

            // Logical
            case 'and': return (await this.eval(args[0], context)) && (await this.eval(args[1], context));
            case 'or': return (await this.eval(args[0], context)) || (await this.eval(args[1], context));
            case 'not': return !(await this.eval(args[0], context));

            // Comparison & Arithmetic
            case 'eq': return (await this.eval(args[0], context)) === (await this.eval(args[1], context));
            case 'lt': return (await this.eval(args[0], context)) < (await this.eval(args[1], context));
            case 'gt': return (await this.eval(args[0], context)) > (await this.eval(args[1], context));
            case 'mod': return (await this.eval(args[0], context)) % (await this.eval(args[1], context));
            case 'add': return (await this.eval(args[0], context)) + (await this.eval(args[1], context));
            case 'subtract': return (await this.eval(args[0], context)) - (await this.eval(args[1], context));

            // Debugging
            case 'log': {
                const resolvedArgs = await Promise.all(args.map(arg => this.eval(arg, context)));
                console.log('[Tailmix Interpreter Log]', ...resolvedArgs);
                return;
            }
            default:
                console.warn(`Tailmix: Unknown operation "${op}"`);
        }
    }

    async evalBranch(branch, context) {
        if (!branch) return;
        for (const expr of branch) {
            await this.eval(expr, context);
        }
    }
}