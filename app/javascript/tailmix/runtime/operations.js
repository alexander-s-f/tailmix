import {ExpressionEvaluator} from "./expression_evaluator";

// Helper to get the top-level state key from an expression
const getStateKey = (expression) => {
    if (expression[0] !== 'state' || !expression[1]) {
        console.warn("Tailmix: This operation currently only supports direct state properties (e.g., `state.foo`).");
        return null;
    }
    return expression[1];
}

const getCsrfToken = () => {
    const token = document.querySelector('meta[name="csrf-token"]');
    return token ? token.content : null;
}

const toQueryString = (params) => {
    return Object.entries(params)
        .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
        .join('&');
}

export const OPERATIONS = {
    set: (interpreter, instruction, scope, runtimeContext) => {
        const stateKey = getStateKey(instruction.args[0]);
        if (!stateKey) return;
        const evaluator = new ExpressionEvaluator(scope);
        const value = evaluator.evaluate(instruction.args[1]);
        runtimeContext.component.update({ [stateKey]: value });
    },

    toggle: (interpreter, instruction, scope, runtimeContext) => {
        const stateKey = getStateKey(instruction.args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const currentValue = evaluator.evaluate(instruction.args[0]);

        runtimeContext.component.update({ [stateKey]: !currentValue });
    },

    increment: (interpreter, instruction, scope, runtimeContext) => {
        const stateKey = getStateKey(instruction.args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const by = instruction.args[1] ? evaluator.evaluate(instruction.args[1]) : 1;
        const currentValue = evaluator.evaluate(instruction.args[0]) || 0;

        runtimeContext.component.update({ [stateKey]: currentValue + by });
    },

    decrement: (interpreter, instruction, scope, runtimeContext) => {
        const stateKey = getStateKey(instruction.args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const by = instruction.args[1] ? evaluator.evaluate(instruction.args[1]) : 1;
        const currentValue = evaluator.evaluate(instruction.args[0]) || 0;

        runtimeContext.component.update({ [stateKey]: currentValue - by });
    },

    push: (interpreter, instruction, scope, runtimeContext) => {
        const stateKey = getStateKey(instruction.args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const currentArray = evaluator.evaluate(instruction.args[0]) || [];
        const value = evaluator.evaluate(instruction.args[1]);
        if (!Array.isArray(currentArray)) {
            console.warn(`Tailmix: 'push' expected a state property of type Array, but got something else for '${stateKey}'.`);
            return;
        }
        runtimeContext.component.update({ [stateKey]: [...currentArray, value] });
    },

    delete: (interpreter, instruction, scope, runtimeContext) => {
        const stateKey = getStateKey(instruction.args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const currentArray = evaluator.evaluate(instruction.args[0]) || [];
        const valueToDelete = evaluator.evaluate(instruction.args[1]);
        if (!Array.isArray(currentArray)) {
            console.warn(`Tailmix: 'delete' expected a state property of type Array, but got something else for '${stateKey}'.`);
            return;
        }

        const index = currentArray.findIndex(item => JSON.stringify(item) === JSON.stringify(valueToDelete));
        if (index > -1) {
            const newArray = [...currentArray];
            newArray.splice(index, 1);
            runtimeContext.component.update({ [stateKey]: newArray });
        }
    },

    dispatch: (interpreter, instruction, scope) => {
        const evaluator = new ExpressionEvaluator(scope);
        const eventName = evaluator.evaluate(instruction.args[0]);
        const detail = evaluator.evaluate(instruction.args[1]);
        const element = scope.find('event')?.currentTarget;

        if (element && eventName) {
            element.dispatchEvent(new CustomEvent(eventName, { bubbles: true, detail }));
        }
    },

    log: (interpreter, instruction, scope) => {
        const evaluator = new ExpressionEvaluator(scope);
        const resolvedArgs = instruction.args.map(arg => evaluator.evaluate(arg));
        console.log('[Tailmix Log]', ...resolvedArgs);
    },

    fetch: async (interpreter, instruction, scope, runtimeContext, elementDef) => {
        const evaluator = new ExpressionEvaluator(scope);
        let url = evaluator.evaluate(instruction.url);
        const options = evaluator.evaluate(instruction.options) || {};

        const method = (options.method || 'get').toUpperCase();
        const params = options.params || {};
        const headers = {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            ...options.headers
        };

        // Evaluate each value within the params object
        const evaluatedParams = {};
        for (const key in params) {
            if (Object.hasOwn(params, key)) {
                evaluatedParams[key] = evaluator.evaluate(params[key]);
            }
        }

        const csrfToken = getCsrfToken();
        if (csrfToken && method !== 'GET') {
            headers['X-CSRF-Token'] = csrfToken;
        }

        const fetchOptions = {
            method: method,
            headers: headers
        };

        if (Object.keys(evaluatedParams).length > 0) {
            if (method === 'GET') {
                const queryString = toQueryString(evaluatedParams);
                url = `${url}${url.includes('?') ? '&' : '?'}${queryString}`;
            } else {
                fetchOptions.body = JSON.stringify(evaluatedParams);
                headers['Content-Type'] = 'application/json';
            }
        }

        try {
            const response = await fetch(url, fetchOptions);
            const responseData = await response.json().catch(() => ({}));

            if (response.ok) {
                const responseProxy = { data: responseData, status: response.status, headers: response.headers };
                await scope.inNewScope(async successScope => {
                    successScope.define('response', responseProxy);
                    for (const successInstruction of instruction.on_success) {
                        const handler = OPERATIONS[successInstruction.operation];
                        if (handler) await handler(interpreter, successInstruction, successScope, runtimeContext, elementDef);
                    }
                });
            } else {
                const errorProxy = {
                    message: `HTTP error! Status: ${response.status}`,
                    status: response.status,
                    data: responseData
                };
                throw errorProxy;
            }
        } catch (error) {
            console.error("Tailmix fetch error:", error);
            if (instruction.on_error && instruction.on_error.length > 0) {
                await scope.inNewScope(async errorScope => {
                    errorScope.define('error', error);
                    for (const errorInstruction of instruction.on_error) {
                        const handler = OPERATIONS[errorInstruction.operation];
                        if (handler) await handler(interpreter, errorInstruction, errorScope, runtimeContext, elementDef);
                    }
                });
            }
        }
    },
};