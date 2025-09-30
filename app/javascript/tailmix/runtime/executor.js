// Nested, stateless evaluator for S-expressions
const ExpressionExecutor = {
    evaluate(expression, context) {
        if (!Array.isArray(expression)) {
            return expression; // This is the literal meaning
        }

        const [op, ...args] = expression;
        switch (op) {
            case 'state':
            case 'this':
            case 'var':
                return args.reduce((obj, key) => obj?.[key], context.vars?.[args.shift()]);
            case 'find':
                const collection = this.evaluate(args[0], context);
                const query = this.evaluate(args[1], context);
                return collection?.find(item =>
                    Object.entries(query).every(([key, value]) => item[key] === value)
                );
            case 'param':
                return args.reduce((obj, key) => obj?.[key], context[op]);
            case 'eq':
                return this.evaluate(args[0], context) === this.evaluate(args[1], context);
            case 'not':
                return !this.evaluate(args[0], context);
            // ... TODO: here will be other operators: gt, lt, and, or ...
            default:
                console.warn(`Unknown expression operator: ${op}`);
                return null;
        }
    }
};

// Главный Executor (VM)
export class Executor {
    /**
     * @param {Array} program - "Render Program" for the element.
     * @param {Object} state - Full component state.
     * @param {Object} withData - Render-time parameters (from ui.element(...)).
     */
    execute(program, state, withData) {
        let context = this.buildInitialContext(state, withData);
        let attributeSet = {
            classes: new Set(),
            data: {},
            other: {}
        };

        for (const instruction of program) {
            const [opcode, args] = instruction;

            // Each instruction can update both the context and the set of attributes.
            const result = this.executeInstruction(opcode, args, context, attributeSet);
            context = result.context;
            attributeSet = result.attributeSet;
        }

        return attributeSet;
    }

    executeInstruction(opcode, args, context, set) {
        switch (opcode) {
            case 'setup_context':
                return this.applySetupContext(context, set, args);
            case 'define_var':
                return { context: this.applyDefineVar(context, args), attributeSet: set };
            case 'evaluate_and_apply_classes':
                return { context, attributeSet: this.applyClasses(context, set, args) };
            case 'evaluate_and_apply_attribute':
                return { context, attributeSet: this.applyAttribute(context, set, args) };
            case 'setup_model_binding':
                return { context, attributeSet: this.applyModelBinding(context, set, args) };
            // ... TODO: other instructions
        }
        return { context, attributeSet: set };
    }

    buildInitialContext(state, withData) {
        return { state, param: withData };
    }

    // --- Instruction Implementation ---

    applySetupContext(context, set, args) {
        const paramValue = ExpressionExecutor.evaluate(args.lookup, context);
        if (paramValue === null || paramValue === undefined) return { context, attributeSet: set };

        const collectionName = args.collection[1]; // [:state, :tabs] -> 'tabs'
        const collection = context.state[collectionName];
        if (!Array.isArray(collection)) return { context, attributeSet: set };

        const keyName = args.name;
        const item = collection.find(i => String(i[keyName]) === String(paramValue));
        if (!item) return { context, attributeSet: set };

        const newSet = { ...set, data: { ...set.data, [`data-tailmix-key-${keyName}`]: paramValue } };
        const newContext = { ...context, item, this: { key: { [keyName]: item } } };

        return { context: newContext, attributeSet: newSet };
    }

    applyDefineVar(context, args) {
        const value = ExpressionExecutor.evaluate(args.expression, context);
        const newVars = { ...(context.vars || {}), [args.name]: value };
        return { ...context, vars: newVars };
    }

    applyClasses(context, set, args) {
        const value = ExpressionExecutor.evaluate(args.condition, context);
        const classesToApply = args.variants[value];
        if (!classesToApply || classesToApply.length === 0) return set;

        const newClasses = new Set([...set.classes, ...classesToApply]);
        return { ...set, classes: newClasses };
    }

    applyAttribute(context, set, args) {
        const value = ExpressionExecutor.evaluate(args.expression, context);
        if (value === null || value === undefined) return set;

        const newOther = { ...set.other };
        if (args.is_content) {
            newOther.content = value;
        } else {
            newOther[args.attribute] = value;
        }
        return { ...set, other: newOther };
    }

    applyModelBinding(context, set, args) {
        const attributeName = args.target[1]; // ['this', 'value'] -> 'value'
        const stateKey = args.state[1];      // ['state', 'type']  -> 'type'
        const value = ExpressionExecutor.evaluate(args.state, context);

        const newOther = { ...set.other, [attributeName]: value };
        const newData = {
            ...set.data,
            'data-tailmix-model-attr': attributeName,
            'data-tailmix-model-state': stateKey,
            'data-tailmix-model-event': args.options?.on || 'input'
        };

        return { ...set, other: newOther, data: newData };
    }
}