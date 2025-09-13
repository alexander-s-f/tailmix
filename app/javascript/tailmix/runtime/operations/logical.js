// Operations related to logic and control flow.
export const LogicalOperations = {
    and: async (interpreter, args, context) => {
        return (await interpreter.eval(args[0], context)) && (await interpreter.eval(args[1], context));
    },

    or: async (interpreter, args, context) => {
        return (await interpreter.eval(args[0], context)) || (await interpreter.eval(args[1], context));
    },

    not: async (interpreter, args, context) => {
        return !(await interpreter.eval(args[0], context));
    },

    if: async (interpreter, args, context) => {
        const [condition, thenBranch, elseBranch] = args;
        if (await interpreter.eval(condition, context)) {
            await interpreter.run(thenBranch, context);
        } else if (elseBranch) {
            await interpreter.run(elseBranch, context);
        }
    },
};
