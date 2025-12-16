export class Scope {
    constructor(state = {}, param = {}, element = null) {
        this.state = state;
        this.param = param;
        this.element = element; // The actual DOM node for this
        this.locals = {};
    }

    resolve(domain, pathString) {
        let root;

        switch (domain) {
            case 'state':
                root = this.state;
                break;
            case 'param':
                root = this.param;
                break;
            case 'this':
                // On the client, this is the element
                if (!this.element) return null;
                root = this.element;
                break;
            case 'local':
                root = this.locals;
                break;
            case 'event':
                // pathString: "value", "target.value", "type"
                if (!this.locals.event) return null;

                // Simplification: if "value" is requested, return event.target.value for input events
                if (pathString === 'value' && this.locals.event.target) {
                    return this.locals.event.target.value;
                }
                // It is possible to add access to keys, preventDefault, etc.
                return this.locals.event[pathString];
            default:
                return null;
        }

        if (!pathString) return root;

        const keys = pathString.split('.');
        let current = root;

        for (const key of keys) {
            if (current === null || current === undefined) {
                return null;
            }
            current = current[key];
        }

        return current;
    }
}