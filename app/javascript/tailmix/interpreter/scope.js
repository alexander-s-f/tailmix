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