import {ExpressionEvaluator} from "./expression_evaluator";

export const OPERATIONS = {
    set: (interpreter, args, scope, runtimeContext) => {
        const statePropertyExpr = args[0]; // This is the full expression, e.g., ['state', 'type']
        const valueExpr = args[1];

        // We can't just take the key, we need to know the full path.
        // For now, we assume `set` only works on top-level state keys.
        const stateKey = statePropertyExpr[1];
        if (statePropertyExpr[0] !== 'state' || !stateKey) {
            console.warn("Tailmix: `set` operation currently only supports direct state properties (e.g., `state.foo`).");
            return;
        }

        const evaluator = new ExpressionEvaluator(scope);
        const value = evaluator.evaluate(valueExpr);

        if (value === undefined) {
            console.warn(`Tailmix: 'set' for '${stateKey}' received 'undefined'. Aborting.`);
            return;
        }
        runtimeContext.component.update({ [stateKey]: value });
    },

    toggle: (interpreter, args, scope, runtimeContext) => {
        const statePropertyExpr = args[0];
        const stateKey = statePropertyExpr[1];
        if (statePropertyExpr[0] !== 'state' || !stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const currentValue = evaluator.evaluate(statePropertyExpr);

        runtimeContext.component.update({ [stateKey]: !currentValue });
    },

    increment: (interpreter, args, scope, runtimeContext) => {
        const statePropertyExpr = args[0]; // e.g., ['state', 'count']
        const stateKey = statePropertyExpr[1];
        if (statePropertyExpr[0] !== 'state' || !stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const by = args[1] ? evaluator.evaluate(args[1]) : 1;

        // Correctly evaluate `state.count` to get its current value
        const currentValue = evaluator.evaluate(statePropertyExpr) || 0;

        runtimeContext.component.update({ [stateKey]: currentValue + by });
    },

    log: (interpreter, args, scope) => {
        const evaluator = new ExpressionEvaluator(scope);
        const resolvedArgs = args.map(arg => evaluator.evaluate(arg));
        console.log('[Tailmix Log]', ...resolvedArgs);
    },
};