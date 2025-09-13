// Operations related to arithmetic.
export const ArithmeticOperations = {
    add: async (interpreter, args, context) => {
        const val1 = await interpreter.eval(args[0], context);
        const val2 = await interpreter.eval(args[1], context);
        return val1 + val2;
    },

    subtract: async (interpreter, args, context) => {
        const val1 = await interpreter.eval(args[0], context);
        const val2 = await interpreter.eval(args[1], context);
        return val1 - val2;
    },

    mod: async (interpreter, args, context) => {
        const val1 = await interpreter.eval(args[0], context);
        const val2 = await interpreter.eval(args[1], context);
        return val1 % val2;
    },
};
