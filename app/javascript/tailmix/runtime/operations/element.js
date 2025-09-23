
export const ElementOperations = {
    // This operation computes attributes for the element considering the temporal context `with`.
    element_attrs: async (interpreter, args, context) => {
        const [elementName, withDataExpr] = args;
        const withData = await interpreter.eval(withDataExpr, context);

        // We delegate computation to the component itself, which has access
        // to its definition and state.
        return interpreter.component.buildScopedAttributes(elementName, withData);
    }
};