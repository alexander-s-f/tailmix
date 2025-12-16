export class Evaluator {
    constructor(scope) {
        this.scope = scope;
    }

    evaluate(expr) {
        if (!Array.isArray(expr)) {
            return expr;
        }

        const [op, arg1, arg2] = expr;

        switch (op) {
            // Variables
            case 'state':
            case 'param':
            case 'this':
                return this.scope.resolve(op, arg1);

            // Logic
            case 'eq':
                return this.evaluate(arg1) == this.evaluate(arg2);
            case 'neq':
                return this.evaluate(arg1) != this.evaluate(arg2);
            case 'not':
                return !this.evaluate(arg1);
            case 'and':
                return this.evaluate(arg1) && this.evaluate(arg2);
            case 'or':
                return this.evaluate(arg1) || this.evaluate(arg2);
            case 'gt':
                return this.evaluate(arg1) > this.evaluate(arg2);
            case 'lt':
                return this.evaluate(arg1) < this.evaluate(arg2);
            case 'gte':
                return this.evaluate(arg1) >= this.evaluate(arg2);
            case 'lte':
                return this.evaluate(arg1) <= this.evaluate(arg2);

            // Math
            case 'add': return this.evaluate(arg1) + this.evaluate(arg2);
            case 'sub': return this.evaluate(arg1) - this.evaluate(arg2);
            case 'mul': return this.evaluate(arg1) * this.evaluate(arg2);
            case 'div': return this.evaluate(arg1) / this.evaluate(arg2);

            // Helpers
            case 'concat': return String(this.evaluate(arg1)) + String(this.evaluate(arg2));

            // switch (op)
            case 'event':
                return this.scope.resolve('event', arg1); // arg1 = "value"

            case 'len':
                const val = this.evaluate(arg1);
                return val ? String(val).length : 0;

            default:
                console.warn(`[Tailmix] Unknown opcode: ${op}`);
                return null;
        }
    }

    normalize(val) {
        return val;
    }
}