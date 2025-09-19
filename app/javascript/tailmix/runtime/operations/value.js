// Operations that produce or manipulate values like strings and dates.
export const ValueOperations = {
    state: (interpreter, args) => {
        return interpreter.component.state[args[0]];
    },

    // event: (interpreter, args, context) => {
    //     return args[0].split('.').reduce((obj, key) => obj?.[key], context.event);
    // },

    event: (interpreter, args, context) => {
        // args - ['target', 'value']
        return args.reduce((obj, key) => obj?.[key], context.event);
    },

    now: () => {
        return new Date().toISOString();
    },

    concat: async (interpreter, args, context) => {
        const resolvedArgs = await Promise.all(args.map(arg => interpreter.eval(arg, context)));
        return resolvedArgs.join('');
    },

    log: async (interpreter, args, context) => {
        const evalPromises = args.map(arg => interpreter.eval(arg, context));
        const resolvedArgs = await Promise.all(evalPromises);
        console.log('[Tailmix Interpreter Log]', ...resolvedArgs);
    },
};
