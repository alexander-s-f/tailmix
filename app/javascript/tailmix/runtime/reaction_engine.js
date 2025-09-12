// app/javascript/tailmix/runtime/reaction_engine.js

/**
 * The ReactionEngine is responsible for running reactions in response to state changes.
 * It listens for state updates and executes the appropriate reaction scripts
 * using the interpreter.
 */
export class ReactionEngine {
    /**
     * @param {import('./component').Component} component The component instance.
     * @param {import('./interpreter').Interpreter} interpreter The interpreter instance.
     */
    constructor(component, interpreter) {
        this.component = component;
        this.interpreter = interpreter;
        this.definition = component.definition;
    }

    /**
     * This method is called by the component after every state change.
     * @param {Set<string>} changedKeys A set of state keys that have changed.
     */
    run(changedKeys) {
        // Use a Set to ensure we run each unique reaction script only once,
        // even if it's triggered by multiple changed keys.
        const reactionsToRun = new Set();

        changedKeys.forEach(key => {
            const reactionsForKey = this.definition.reactions?.[key];
            if (reactionsForKey) {
                reactionsForKey.forEach(reactionDef => {
                    // We stringify to ensure uniqueness of the expression array in the Set
                    reactionsToRun.add(JSON.stringify(reactionDef.expressions));
                });
            }
        });

        reactionsToRun.forEach(expressionsString => {
            const expressions = JSON.parse(expressionsString);
            // Reactions are not tied to a specific DOM event, so we pass null
            this.interpreter.run(expressions, null);
        });
    }
}