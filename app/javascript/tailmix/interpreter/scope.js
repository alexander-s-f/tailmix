
export class Scope {
    constructor(state = {}, param = {}, element = null, variants = {}) {
        this.state    = state;
        this.param    = param;
        this.element  = element;
        this.variants = variants;
        this.locals   = {};
    }

    // pathArg can be a string ("user.name") or an array (["user", "name"])
    resolve(domain, pathArg) {
        let keys = [];
        if (Array.isArray(pathArg)) {
            keys = pathArg;
        } else if (typeof pathArg === 'string' && pathArg.length > 0) {
            keys = pathArg.split('.');
        }

        let root;
        switch (domain) {
            case 'state':   root = this.state;    break;
            case 'param':   root = this.param;    break;
            case 'local':   root = this.locals;   break;
            case 'variant': root = this.variants; break;
            case 'this':
                if (!this.element) return null;
                root = this.element;
                break;
            case 'event': {
                if (!this.locals.event) return null;
                // event.value -> target.value (inputs)
                // event.detail.id -> CustomEvent detail
                let obj = this.locals.event;
                for (const key of keys) {
                    if (key === 'value' && obj && obj.target) {
                        obj = obj.target.value;
                    } else {
                        obj = obj?.[key];
                    }
                }
                return obj ?? null;
            }
            default: return null;
        }

        if (keys.length === 0) return root;

        let current = root;
        for (const key of keys) {
            if (current === null || current === undefined) return null;
            current = current[key];
        }
        return current;
    }

    clone() {
        const s = new Scope(this.state, this.param, this.element, this.variants);
        s.locals = { ...this.locals };
        return s;
    }
}
