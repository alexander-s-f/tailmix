import { Scope } from './scope';

/**
 * Encapsulates the entire live execution context for a single component instance.
 * This object is passed into closures (like event handlers) to provide a stable
 * reference to the component's "living" parts (state, scope, etc.).
 */
export class RuntimeContext {
    constructor(component) {
        this.component = component;
        this._state = component._state; // Direct reference to the mutable state object

        // The scope is created once and holds a reference to the state.
        this.scope = new Scope({ state: this._state });
    }

    /**
     * Called by the component when its state is updated.
     * This ensures the context remains synchronized, although in our current model
     * with a direct reference, this might not be strictly needed, but it's good practice.
     */
    onStateUpdate() {
        // For now, we can just recreate the scope if needed, or do nothing
        // since it holds a direct reference. Let's keep it simple.
        // In the future, this is where we could clear caches.
    }
}