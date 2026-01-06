
export class Scope {
    constructor(state = {}, param = {}, element = null) {
        this.state = state;
        this.param = param;
        this.element = element;
        this.locals = {};
    }

    // pathArg can be a string ("user.name") or an array (["user", "name"])
    resolve(domain, pathArg) {
        let root;

        let keys = [];
        if (Array.isArray(pathArg)) {
            keys = pathArg;
        } else if (typeof pathArg === 'string') {
            keys = pathArg.split('.');
        } else if (pathArg === undefined || pathArg === null) {
            keys = [];
        }

        switch (domain) {
            case 'state':
                root = this.state;
                break;
            case 'param':
                root = this.param;
                break;
            case 'local':
                root = this.locals;
                break;
            case 'this':
                if (!this.element) return null;
                root = this.element;
                break;
            case 'event':
                if (!this.locals.event) return null;

                const key = keys[0];
                if (key === 'value' && this.locals.event.target) {
                    return this.locals.event.target.value;
                }
                return this.locals.event[key];
            default:
                return null;
        }

        if (keys.length === 0) return root;

        let current = root;
        for (const key of keys) {
            if (current === null || current === undefined) {
                return null;
            }
            current = current[key];
        }

        return current;
    }

    clone() {
        const s = new Scope(this.state, this.param, this.element);
        s.locals = { ...this.locals };
        return s;
    }
}