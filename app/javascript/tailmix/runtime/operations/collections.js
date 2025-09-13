// Operations related to collection/array manipulation
export const CollectionsOperations = {
    array_push: async (interpreter, args, context) => {
        const [key, value] = args;
        const currentArray = interpreter.component.state[key] || [];
        const newValue = await interpreter.eval(value, context);
        interpreter.component.update({ [key]: [...currentArray, newValue] });
    },

    array_remove_at: async (interpreter, args, context) => {
        const [key, index] = args;
        const currentArray = interpreter.component.state[key] || [];
        const resolvedIndex = await interpreter.eval(index, context);
        const newArray = currentArray.filter((_, i) => i !== resolvedIndex);
        interpreter.component.update({ [key]: newArray });
    },

    array_update_at: async (interpreter, args, context) => {
        const [key, index, value] = args;
        const currentArray = interpreter.component.state[key] || [];
        const resolvedIndex = await interpreter.eval(index, context);
        const newValue = await interpreter.eval(value, context);
        const newArray = currentArray.map((item, i) => (i === resolvedIndex ? newValue : item));
        interpreter.component.update({ [key]: newArray });
    },
};
