import {ExpressionEvaluator} from "./expression_evaluator";
import { buildNestedState, getStateKey, toQueryString, getCsrfToken  } from './utils';

// A map to store debounce timers for each element, preventing clashes.
const debounceTimers = new WeakMap();

export const OPERATIONS = {
    set: (interpreter, instruction, scope, runtimeContext) => {
        const args = instruction.args;
        const statePathExpr = args[0];
        // The path starts after the 'state' keyword
        const statePath = statePathExpr.slice(1);

        if (statePathExpr[0] !== 'state' || statePath.length === 0) {
            console.warn("Tailmix: `set` operation requires a state property.", statePathExpr);
            return;
        }

        const evaluator = new ExpressionEvaluator(scope);
        const value = evaluator.evaluate(args[1]);

        if (value === undefined) {
            console.warn(`Tailmix: 'set' for '${statePath.join('.')}' received 'undefined'. Aborting.`);
            return;
        }

        const newState = buildNestedState(statePath, value);
        runtimeContext.component.update(newState);
    },

    toggle: (interpreter, instruction, scope, runtimeContext) => {
        // ... (toggle logic needs a similar deep update if we want to toggle nested booleans)
        // For now, let's assume it works on top-level state
        const stateKey = instruction.args[0][1];
        if (!stateKey) return;
        const evaluator = new ExpressionEvaluator(scope);
        const currentValue = evaluator.evaluate(instruction.args[0]);
        runtimeContext.component.update({ [stateKey]: !currentValue });
    },

    increment: (interpreter, instruction, scope, runtimeContext) => {
        const args = instruction.args;
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;
        const evaluator = new ExpressionEvaluator(scope);
        const by = args[1] ? evaluator.evaluate(args[1]) : 1;
        const currentValue = evaluator.evaluate(args[0]) || 0;
        runtimeContext.component.update({ [stateKey]: currentValue + by });
    },

    decrement: (interpreter, instruction, scope, runtimeContext) => {
        const args = instruction.args;
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;
        const evaluator = new ExpressionEvaluator(scope);
        const by = args[1] ? evaluator.evaluate(args[1]) : 1;
        const currentValue = evaluator.evaluate(args[0]) || 0;
        runtimeContext.component.update({ [stateKey]: currentValue - by });
    },

    push: (interpreter, instruction, scope, runtimeContext) => {
        const args = instruction.args;
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;
        const evaluator = new ExpressionEvaluator(scope);
        const currentArray = evaluator.evaluate(args[0]) || [];
        const value = evaluator.evaluate(args[1]);
        runtimeContext.component.update({ [stateKey]: [...currentArray, value] });
    },

    delete: (interpreter, instruction, scope, runtimeContext) => {
        const args = instruction.args;
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;
        const evaluator = new ExpressionEvaluator(scope);
        const currentArray = evaluator.evaluate(args[0]) || [];
        const valueToDelete = evaluator.evaluate(args[1]);
        const index = currentArray.findIndex(item => JSON.stringify(item) === JSON.stringify(valueToDelete));
        if (index > -1) {
            const newArray = [...currentArray];
            newArray.splice(index, 1);
            runtimeContext.component.update({ [stateKey]: newArray });
        }
    },

    dispatch: (interpreter, instruction, scope) => {
        const args = instruction.args;
        const evaluator = new ExpressionEvaluator(scope);
        const eventName = evaluator.evaluate(args[0]);
        const detail = evaluator.evaluate(args[1]);
        const element = scope.find('event')?.currentTarget;
        if (element && eventName) {
            element.dispatchEvent(new CustomEvent(eventName, { bubbles: true, detail }));
        }
    },

    set_interval: (interpreter, instruction, scope, runtimeContext, elementDef) => {
        const evaluator = new ExpressionEvaluator(scope);
        const delay = evaluator.evaluate(instruction.delay);
        const targetProperty = instruction.target_property; // This is a path like ['state', 'timer_id']
        const stateKey = getStateKey(targetProperty);

        if (!stateKey) {
            console.warn("Tailmix: `set_interval` requires a direct state property as its first argument.");
            return;
        }

        const timerId = setInterval(() => {
            interpreter.run(instruction.instructions, {}, runtimeContext, elementDef);
        }, delay);

        // Store the timer ID in the specified state property
        runtimeContext.component.update({ [stateKey]: timerId });
    },

    clear_interval: (interpreter, instruction, scope) => {
        const args = instruction.args;
        const evaluator = new ExpressionEvaluator(scope);
        const timerId = evaluator.evaluate(args[0]);
        if (timerId) {
            clearInterval(timerId);
        }
    },

    log: (interpreter, instruction, scope, runtimeContext) => {
        // console.log(prettyJSON(instruction.args));
        // console.log(prettyJSON(scope));
        // console.log(prettyJSON(runtimeContext));

        const args = instruction.args;
        const evaluator = new ExpressionEvaluator(scope);
        const resolvedArgs = args.map(arg => evaluator.evaluate(arg));
        const componentName = runtimeContext.component.definition.name;
        console.log(`[Tailmix Log - ${componentName}]`, ...resolvedArgs);
    },

    debounce: async (interpreter, instruction, scope, runtimeContext, elementDef) => {
        const element = scope.find('event')?.currentTarget;
        if (!element) {
            console.warn("Tailmix: `debounce` can only be used in an event context.");
            return;
        }

        if (debounceTimers.has(element)) {
            clearTimeout(debounceTimers.get(element));
        }

        // Pass the original context to the debounced call
        const originalContext = { event: scope.find('event'), payload: scope.find('payload') };

        const timer = setTimeout(() => {
            debounceTimers.delete(element);
            interpreter.run(instruction.instructions, originalContext, runtimeContext, elementDef);
        }, instruction.delay);

        debounceTimers.set(element, timer);
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