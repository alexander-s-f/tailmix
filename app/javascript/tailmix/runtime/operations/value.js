// Operations that produce or manipulate values like strings and dates.
export const ValueOperations = {
    state: (interpreter, args, context) => {
        return interpreter.component.state[args[0]];
    },

    event: (interpreter, args, context) => {
        // args - ['target', 'value']
        return args.reduce((obj, key) => obj?.[key], context.event);
    },

    // Allows access to the data passed to the action.
    // [:payload] -> context.payload
    // [:payload, 'id'] -> context.payload?.id
    payload: (interpreter, args, context) => {
        if (!context || context.payload === undefined) {
            console.warn("Tailmix: `payload` can only be used inside an action triggered by an event.");
            return null;
        }
        return args.reduce((obj, key) => obj?.[key], context.payload);
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

    item: (interpreter, args, context) => {
        if (!context || context.item === undefined) {
            console.warn("Tailmix: `item` can only be used inside an `each` block.");
            return null;
        }
        return args.reduce((obj, key) => obj?.[key], context.item);
    },
};
