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

        // --- Property Access ---
        if (['state', 'param', 'this'].includes(op)) {
            const value = this.scope.find(op);
            return args.reduce((obj, key) => obj?.[key], value);
        }
        if (op === 'var') {
            const [varName, ...path] = args;
            const value = this.scope.find(varName);
            return path.reduce((obj, key) => obj?.[key], value);
        }

        // --- Collection Operations ---
        if (['find', 'sum', 'avg', 'min', 'max', 'size'].includes(op)) {
            return this.evaluateCollectionOperation(op, args);
        }

        // --- Function Calls & Ternary ---
        switch (op) {
            case 'iif':
                return this.evaluate(args[0]) ? this.evaluate(args[1]) : this.evaluate(args[2]);
            case 'upcase':
                return String(this.evaluate(args[0])).toUpperCase();
            case 'downcase':
                return String(this.evaluate(args[0])).toLowerCase();
            case 'capitalize':
                const str = String(this.evaluate(args[0]));
                return str.charAt(0).toUpperCase() + str.slice(1);
            case 'slice':
                const strSlice = String(this.evaluate(args[0]));
                const start = this.evaluate(args[1]);
                const length = args.length > 2 ? this.evaluate(args[2]) : undefined;
                return strSlice.slice(start, length === undefined ? undefined : start + length);
            case 'includes':
                return String(this.evaluate(args[0])).includes(String(this.evaluate(args[1])));
            case 'concat':
                return args.map(arg => this.evaluate(arg)).join('');
        }

        // --- Binary and Unary Operations ---
        const left = args[0] ? this.evaluate(args[0]) : null;
        const right = args[1] ? this.evaluate(args[1]) : null;

        switch (op) {
            case 'eq': return left === right;
            case 'not': return !left;
            case 'gt': return left > right;
            case 'lt': return left < right;
            case 'gte': return left >= right;
            case 'lte': return left <= right;
            case 'add': return left + right;
            case 'sub': return left - right;
            case 'mul': return left * right;
            case 'div': return left / right;
            case 'concat': return args.map(arg => this.evaluate(arg)).join('');
            default:
                console.warn(`Unknown expression operator: ${op}`);
                return null;
        }
    }

    evaluateCollectionOperation(op, args) {
        const collection = this.evaluate(args[0]);
        if (!Array.isArray(collection)) return null;
        const prop = args[1] ? this.evaluate(args[1]) : null;
        const values = prop ? collection.map(item => item[prop]).filter(v => v != null) : collection.filter(v => v != null);

        switch (op) {
            case 'find':
                const query = this.evaluate(args[1]);
                return collection.find(item =>
                    Object.entries(query).every(([key, value]) => String(item[key]) === String(this.evaluate(value)))
                );
            case 'size':
                return collection.length;
            case 'sum':
                return values.reduce((sum, current) => sum + current, 0);
            case 'avg':
                if (values.length === 0) return 0;
                return values.reduce((sum, current) => sum + current, 0) / values.length;
            case 'min':
                return Math.min(...values);
            case 'max':
                return Math.max(...values);
            default:
                return null;
        }
    }
}