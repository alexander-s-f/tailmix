const extractStateKey = (expression) => {
    if (Array.isArray(expression) && expression[0] === 'state' && expression[1]) {
        return expression[1];
    }
    // For backward compatibility, if a simple string is passed
    if (typeof expression === 'string') {
        return expression;
    }
    console.error("Tailmix: Invalid state expression passed to mutation.", expression);
    return null;
}

export const StateOperations = {
    set: async (interpreter, args, context) => {
        const [stateExpr, valueExpr] = args;
        const stateKey = extractStateKey(stateExpr);
        if (!stateKey) return;

        const resolvedValue = await interpreter.eval(valueExpr, context);
        interpreter.component.update({ [stateKey]: resolvedValue });
    },

    toggle: async (interpreter, args, context) => {
        const [stateExpr] = args;
        const stateKey = extractStateKey(stateExpr);
        if (!stateKey) return;

        const currentValue = interpreter.component.state[stateKey];
        interpreter.component.update({ [stateKey]: !currentValue });
    },

    increment: async (interpreter, args, context) => {
        const [stateExpr, byExpr = 1] = args;
        const stateKey = extractStateKey(stateExpr);
        if (!stateKey) return;

        const currentValue = interpreter.component.state[stateKey] || 0;
        const resolvedBy = await interpreter.eval(byExpr, context);
        interpreter.component.update({ [stateKey]: currentValue + resolvedBy });
    },
};
