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

    array_remove_where: async (interpreter, args, context) => {
        const [key, query] = args;
        const resolvedQuery = await interpreter.eval(query, context);
        const currentArray = interpreter.component.state[key] || [];

        const newArray = currentArray.filter(item => {
            return !Object.entries(resolvedQuery).every(([qKey, qValue]) => item[qKey] === qValue);
        });
        interpreter.component.update({ [key]: newArray });
    },

    array_update_where: async (interpreter, args, context) => {
        const [key, query, data] = args;
        const resolvedQuery = await interpreter.eval(query, context);
        const resolvedData = await interpreter.eval(data, context);
        const currentArray = interpreter.component.state[key] || [];

        const newArray = currentArray.map(item => {
            if (Object.entries(resolvedQuery).every(([qKey, qValue]) => item[qKey] === qValue)) {
                return { ...item, ...resolvedData };
            }
            return item;
        });
        interpreter.component.update({ [key]: newArray });
    },

    each: async (interpreter, args, context) => {
        const [collectionExpr, bodyExprs] = args;
        const collection = await interpreter.eval(collectionExpr, context);

        if (!Array.isArray(collection)) {
            console.warn("Tailmix: `each` was called on a non-array value.", collection);
            return;
        }

        // We use Promise.all for asynchronous iteration execution
        const newCollection = await Promise.all(collection.map(async (item) => {
            let currentItem = (typeof item === 'object' && item !== null) ? { ...item } : item;

            // For each iteration, a new context is created in which the variable `item` will be available
            const loopContext = { ...context, item: currentItem };

            for (const expr of bodyExprs) {
                const [op, ...opArgs] = expr;

                // Intercepting special item commands
                if (op === 'item_update') {
                    if (typeof currentItem === 'object' && currentItem !== null) {
                        const updates = await interpreter.eval(opArgs[0], loopContext);
                        currentItem = { ...currentItem, ...updates };
                    }
                } else if (op === 'item_replace') {
                    currentItem = await interpreter.eval(opArgs[0], loopContext);
                } else {
                    // All other operations are performed in the loopContext
                    await interpreter.eval(expr, loopContext);
                }
            }
            return currentItem;
        }));

        // Finally, we update the component state with the new array
        const stateKey = collectionExpr[1]; // `collectionExpr` is `['state', 'todos']`
        interpreter.component.update({ [stateKey]: newCollection });
    },
};
