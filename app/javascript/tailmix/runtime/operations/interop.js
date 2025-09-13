// Operations for interoperability, like calling other actions.
export const InteropOperations = {
    call: async (interpreter, args, context) => {
        const [actionName] = args;
        const resolvedActionName = await interpreter.eval(actionName, context);
        // We use the component's public API to run the other action.
        // We don't await this, as it kicks off a new, independent execution flow.
        interpreter.component.api.runAction(resolvedActionName, context.event);
    },
};
