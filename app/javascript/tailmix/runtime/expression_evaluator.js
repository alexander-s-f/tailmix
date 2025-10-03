// A shared, stateless service for evaluating Tailmix expressions within a given scope.
export class ExpressionEvaluator {
    constructor(scope) {
        this.scope = scope;
    }

    evaluate(expression) {
        if (!Array.isArray(expression)) {
            return expression; // Literal value
        }

        const [op, ...args] = expression;
        switch (op) {
            case 'state':
            case 'param':
            case 'this': {
                const value = this.scope.find(op);
                return args.reduce((obj, key) => obj?.[key], value);
            }
            case 'var': {
                const [varName, ...path] = args;
                const value = this.scope.find(varName);
                return path.reduce((obj, key) => obj?.[key], value);
            }
            case 'find': {
                const collection = this.evaluate(args[0]);
                const query = this.evaluate(args[1]);
                if (!Array.isArray(collection)) return null;

                return collection.find(item =>
                    Object.entries(query).every(([key, value]) => {
                        // Compare values as strings to be indifferent to string vs. number types from JSON
                        return String(item[key]) === String(this.evaluate(value));
                    })
                );
            }
            case 'eq':
                return this.evaluate(args[0]) === this.evaluate(args[1]);
            case 'not':
                return !this.evaluate(args[0]);
            case 'concat': {
                return args.map(arg => this.evaluate(arg)).join('');
            }
            default:
                console.warn(`Unknown expression operator: ${op}`);
                return null;
        }
    }
}