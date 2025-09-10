import { PipelineInterpreter } from './pipeline_interpreter';

/**
 * The engine that processes declarative reactions (`react on: ...`)
 * in response to changes in the component's state.
 */
export class ReactionEngine {
    constructor(component) {
        this.component = component;
        this.definition = component.definition;
    }

    /**
     * Runs after each state change.
     * @param {Set<string>} changedKeys - A set of state keys that have changed.
     */
    run(changedKeys) {
        const pipelinesToRun = new Set();

        changedKeys.forEach(key => {
            const reactions = this.definition.reactions?.[key];
            if (reactions) {
                reactions.forEach(pipeline => pipelinesToRun.add(JSON.stringify(pipeline)));
            }
        });

        // We launch each unique conveyor.
        pipelinesToRun.forEach(pipelineString => {
            const pipeline = JSON.parse(pipelineString);
            new PipelineInterpreter(pipeline, this.component).run();
        });
    }
}