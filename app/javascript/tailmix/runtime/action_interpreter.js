// This interpreter executes S-expressions for actions.
// It can change state, call other actions, perform logging, etc.
// It does not have access to the DOM, it works only with data.

const extractStateKey = (expression) => {
    if (Array.isArray(expression) && expression[0] === 'state' && expression[1]) {
        return expression[1];
    }
    return null;
}

const resolveKeyContext = (element, component) => {
    const context = { key: {} };
    if (!element || !element.dataset.tailmixElement) return context;

    const elementName = element.dataset.tailmixElement;
    const elementDef = component.definition.elements[elementName];
    if (!elementDef?.key_config) return context;

    const keyConfig = elementDef.key_config;
    const keyName = keyConfig.name;
    const keyValue = element.dataset[`tailmixKey${keyName.charAt(0).toUpperCase() + keyName.slice(1)}`];

    if (keyValue === undefined) return context;

    const collection = component.state[keyConfig.collection];
    if (!Array.isArray(collection)) return context;

    const item = collection.find(i => String(i[keyName]) === String(keyValue));
    if (item) {
        context.key[keyName] = item;
    }

    return context;
};

const OPERATIONS = {
    // --- State Mutations ---
    set: async (interpreter, args, context) => {
        const stateKey = extractStateKey(args[0]);
        if (!stateKey) return;
        const value = await interpreter.evaluate(args[1], context);
        interpreter.component.update({ [stateKey]: value });
    },
    toggle: async (interpreter, args, context) => {
        const stateKey = extractStateKey(args[0]);
        if (!stateKey) return;
        interpreter.component.update({ [stateKey]: !interpreter.component.state[stateKey] });
    },
    increment: async (interpreter, args, context) => {
        const stateKey = extractStateKey(args[0]);
        if (!stateKey) return;
        const by = args[1] ? await interpreter.evaluate(args[1], context) : 1;
        const currentValue = interpreter.component.state[stateKey] || 0;
        interpreter.component.update({ [stateKey]: currentValue + by });
    },

    // --- Value Expressions ---
    this: (interpreter, args, context) => {
        if (!context.event?.currentTarget) return null;
        const element = context.event.currentTarget;
        const keyContext = resolveKeyContext(element, interpreter.component);
        return args.reduce((obj, key) => obj?.[key], keyContext);
    },
    state: (interpreter, args, context) => interpreter.component.state[args[0]],
    param: (interpreter, args, context) => args.reduce((obj, key) => obj?.[key], context.param),

    // --- Functions ---
    log: async (interpreter, args, context) => {
        const resolvedArgs = await Promise.all(args.map(arg => interpreter.evaluate(arg, context)));
        console.log('[Tailmix Log]', ...resolvedArgs);
    },
    concat: async (interpreter, args, context) => {
        const resolvedArgs = await Promise.all(args.map(arg => interpreter.evaluate(arg, context)));
        return resolvedArgs.join('');
    },
};

export class ActionInterpreter {
    constructor(component) {
        this.component = component;
    }

    /**
     * The main method that executes an array of instruction objects.
     * @param {Array<Object>} instructions - [{operation: 'set', args: [...]}, ...]
     * @param {Object} context - The execution context (event, payload).
     */
    async run(instructions, context) {
        if (!instructions) return;

        for (const instruction of instructions) {
            const op = instruction.operation;
            const args = instruction.args;
            const handler = OPERATIONS[op];

            if (handler) {
                await handler(this, args, context);
            } else {
                console.warn(`Unknown action operator: ${op}`);
            }
        }
    }

    /**
     * A helper recursive method for calculating S-expressions,
     * which are passed as ARGUMENTS to instructions.
     * @param {*} expression - An S-expression (e.g., ['state', 'count']) or a literal.
     * @param {Object} context - The execution context.
     */
    async evaluate(expression, context) {
        if (!Array.isArray(expression)) {
            return expression; // Literal meaning
        }

        const [op, ...args] = expression;
        const handler = OPERATIONS[op];

        if (handler) {
            return handler(this, args, context);
        } else {
            console.warn(`Unknown expression operator: ${op}`);
        }
    }
}
