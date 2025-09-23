
export const VariableOperations = {
    let: async (interpreter, args, context) => {
        const [key, valueExpr] = args;
        const value = await interpreter.eval(valueExpr, context);
        // We are adding a variable to the `context` so that it is available
        // for subsequent operations in the same `action`.
        context.vars = context.vars || {};
        context.vars[key] = value;
    },

    var: (interpreter, args, context) => {
        const [key] = args;
        return context.vars?.[key];
    }
};
