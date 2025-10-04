// Manages a stack of variable scopes ("frames") to implement lexical scoping
// for the Tailmix client-side VM.
export class Scope {
    constructor(globalVars = {}) {
        this.stack = [globalVars];
    }

    /**
     * Pushes a new, empty scope onto the stack for local variables.
     * @param {Object} localVars - An object containing local variables.
     */
    push(localVars = {}) {
        this.stack.push(localVars);
    }

    /**
     * Pops the current scope off the stack.
     */
    pop() {
        if (this.stack.length <= 1) {
            throw new Error("Tailmix Scope: Cannot pop the global scope");
        }
        this.stack.pop();
    }

    /**
     * Defines a new variable in the *current* (innermost) scope.
     * @param {string} name - The variable name.
     * @param {*} value - The variable value.
     */
    define(name, value) {
        this.stack[this.stack.length - 1][name] = value;
    }

    /**
     * Finds an existing variable in the scope chain and updates its value.
     * Throws an error if the variable is not found.
     * @param {string} name - The variable name.
     * @param {*} value - The new value.
     */
    set(name, value) {
        for (let i = this.stack.length - 1; i >= 0; i--) {
            if (Object.prototype.hasOwnProperty.call(this.stack[i], name)) {
                this.stack[i][name] = value;
                return;
            }
        }
        throw new Error(`Tailmix Scope: Undefined variable '${name}'. Cannot set value.`);
    }

    /**
     * Finds a variable by searching from the innermost scope to the global scope.
     * @param {string} name - The variable name.
     * @returns {*} The value of the variable, or undefined if not found.
     */
    find(name) {
        for (let i = this.stack.length - 1; i >= 0; i--) {
            if (Object.prototype.hasOwnProperty.call(this.stack[i], name)) {
                return this.stack[i][name];
            }
        }
        return undefined;
    }

    /**
     * A convenience method to execute a block within a new, temporary scope.
     * It now supports async callbacks.
     * @param {Function} callback - The function to execute within the new scope.
     * @param {Object} vars - Initial variables for the new scope.
     */
    async inNewScope(callback, vars = {}) {
        this.push(vars);
        try {
            // FIX: Await the callback to ensure it completes before the scope is popped.
            return await callback(this);
        } finally {
            this.pop();
        }
    }
}
