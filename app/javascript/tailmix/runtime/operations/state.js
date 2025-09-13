// Operations related to state manipulation
export const StateOperations = {
    set: async (interpreter, args) => {
        const [key, value] = args;
        const resolvedValue = await interpreter.eval(value);
        interpreter.component.update({[key]: resolvedValue});
    },

    toggle: async (interpreter, args) => {
        const [key] = args;
        interpreter.component.update({[key]: !interpreter.component.state[key]});
    },

    increment: async (interpreter, args, context) => {
        const [key, by = 1] = args;
        const currentValue = (await interpreter.eval(['state', key], context)) || 0;
        const resolvedBy = await interpreter.eval(by, context);
        interpreter.component.update({ [key]: currentValue + resolvedBy });
    },
};
