import {ExpressionEvaluator} from "./expression_evaluator";

export const OPERATIONS = {
    set: (interpreter, args, scope) => {
        const propertyExpr = args[0];
        const valueExpr = args[1];
        const stateKey = propertyExpr[1];
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const value = evaluator.evaluate(valueExpr);

        if (value === undefined) {
            console.warn(`Tailmix: 'set' operation for '${stateKey}' received 'undefined'. Aborting state update.`);
            return;
        }

        interpreter.component.update({ [stateKey]: value });
    },
    toggle: (interpreter, args, scope) => {
        const stateKey = args[0][1]; // ['property', 'open'] -> 'open'
        if (!stateKey) return;
        interpreter.component.update({ [stateKey]: !scope.find(stateKey) });
    },
    increment: (interpreter, args, scope) => {
        const stateKey = args[0][1]; // ['property', 'count'] -> 'count'
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const by = args[1] ? evaluator.evaluate(args[1]) : 1;
        const currentValue = scope.find(stateKey) || 0;
        interpreter.component.update({ [stateKey]: currentValue + by });
    },
    decrement: (interpreter, args, scope) => {
        const stateKey = args[0][1]; // ['property', 'count'] -> 'count'
        if (!stateKey) return;

        const evaluator = new ExpressionEvaluator(scope);
        const by = args[1] ? evaluator.evaluate(args[1]) : 1;
        const currentValue = scope.find(stateKey) || 0;
        interpreter.component.update({ [stateKey]: currentValue - by });
    },
    log: (interpreter, args, scope) => {
        const evaluator = new ExpressionEvaluator(scope);
        const resolvedArgs = args.map(arg => evaluator.evaluate(arg));
        console.log('[Tailmix Log]', ...resolvedArgs);
    },
};