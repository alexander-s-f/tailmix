// Operations related to comparison.
export const ComparisonOperations = {
    eq: async (interpreter, args, context) => {
        const val1 = await interpreter.eval(args[0], context);
        const val2 = await interpreter.eval(args[1], context);
        return val1 === val2;
    },

    lt: async (interpreter, args, context) => {
        const val1 = await interpreter.eval(args[0], context);
        const val2 = await interpreter.eval(args[1], context);
        return val1 < val2;
    },

    gt: async (interpreter, args, context) => {
        const val1 = await interpreter.eval(args[0], context);
        const val2 = await interpreter.eval(args[1], context);
        return val1 > val2;
    },
};
