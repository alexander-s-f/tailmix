// Operations related to state manipulation
export const StateOperations = {
    set: async (interpreter, args) => {
        const [key, value] = args;
        const resolvedValue = await interpreter.eval(value);
        interpreter.component.update({ [key]: resolvedValue });
    },

    toggle: async (interpreter, args) => {
        const [key] = args;
        interpreter.component.update({ [key]: !interpreter.component.state[key] });
    },

    increment: async (interpreter, args) => {
        const [key, by = 1] = args;
        const currentValue = interpreter.component.state[key] || 0;
        const resolvedBy = await interpreter.eval(by);
        interpreter.component.update({ [key]: currentValue + resolvedBy });
    },
};
