import { Scope } from './scope';

/**
 * Encapsulates the entire live execution context for a single component instance.
 */
export class RuntimeContext {
    constructor(component) {
        this.component = component;
        this._state = component._state;

        this.scope = new Scope({ state: this._state });
    }

    /**
     * Called by the component when its state is updated.
     * We recreate the global scope with a reference to the NEW state object.
     */
    onStateUpdate() {
        this._state = this.component._state;
        this.scope = new Scope({ state: this._state });
    }
}