import {ExpressionEvaluator} from "./expression_evaluator";

// Helper to get the top-level state key from an expression
const getStateKey = (expression) => {
    if (expression[0] !== 'state' || !expression[1]) {
        console.warn("Tailmix: This operation currently only supports direct state properties (e.g., `state.foo`).");
        return null;
    }
    return expression[1];
}

export const OPERATIONS = {
    set: (interpreter, args, scope, runtimeContext) => {
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const value = evaluator.evaluate(args[1]);

        if (value === undefined) {
            console.warn(`Tailmix: 'set' for '${stateKey}' received 'undefined'. Aborting.`);
            return;
        }
        runtimeContext.component.update({ [stateKey]: value });
    },

    toggle: (interpreter, args, scope, runtimeContext) => {
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const currentValue = evaluator.evaluate(args[0]);

        runtimeContext.component.update({ [stateKey]: !currentValue });
    },

    increment: (interpreter, args, scope, runtimeContext) => {
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const by = args[1] ? evaluator.evaluate(args[1]) : 1;
        const currentValue = evaluator.evaluate(args[0]) || 0;

        runtimeContext.component.update({ [stateKey]: currentValue + by });
    },

    decrement: (interpreter, args, scope, runtimeContext) => {
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const by = args[1] ? evaluator.evaluate(args[1]) : 1;
        const currentValue = evaluator.evaluate(args[0]) || 0;

        runtimeContext.component.update({ [stateKey]: currentValue - by });
    },

    push: (interpreter, args, scope, runtimeContext) => {
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const currentArray = evaluator.evaluate(args[0]) || [];
        const value = evaluator.evaluate(args[1]);
        if (!Array.isArray(currentArray)) {
            console.warn(`Tailmix: 'push' expected a state property of type Array, but got something else for '${stateKey}'.`);
            return;
        }
        runtimeContext.component.update({ [stateKey]: [...currentArray, value] });
    },

    delete: (interpreter, args, scope, runtimeContext) => {
        const stateKey = getStateKey(args[0]);
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const currentArray = evaluator.evaluate(args[0]) || [];
        const valueToDelete = evaluator.evaluate(args[1]);
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

    dispatch: (interpreter, args, scope) => {
        const evaluator = new ExpressionEvaluator(scope);
        const eventName = evaluator.evaluate(args[0]);
        const detail = evaluator.evaluate(args[1]);
        const element = scope.find('event')?.currentTarget;

        if (element && eventName) {
            element.dispatchEvent(new CustomEvent(eventName, { bubbles: true, detail }));
        }
    },

    log: (interpreter, args, scope) => {
        const evaluator = new ExpressionEvaluator(scope);
        const resolvedArgs = args.map(arg => evaluator.evaluate(arg));
        console.log('[Tailmix Log]', ...resolvedArgs);
    },
};