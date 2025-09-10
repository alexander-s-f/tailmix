/**
 * An interpreter that executes a single pipeline of reactions.
 * It manages the temporal context for storing intermediate results.
 */
export class PipelineInterpreter {
    constructor(pipeline, component) {
        this.pipeline = pipeline;
        this.component = component;
        this.context = {}; // .result(:my_var)
    }

    run() {
        let lastResult = null; // Result of the last operation

        for (const step of this.pipeline) {
            switch (step.type) {
                case 'compute':
                    lastResult = this.executeCompute(step);
                    break;
                case 'condition':
                    const conditionMet = this.checkCondition(step, lastResult);
                    if (!conditionMet) return; // We interrupt the pipeline if the condition is false.
                    break;
                case 'effect':
                    this.executeEffect(step, lastResult);
                    break;
            }

            // We save the intermediate result if `result_as` is specified.
            if (step.result_as) {
                this.context[step.result_as] = lastResult;
            }
        }
    }

    executeCompute(step) {
        const operands = step.operands.map(op => this.resolveOperand(op));
        switch (step.operator) {
            case 'multiply':
                return operands[0] * operands[1];
            case 'sum':
                return operands[0] + operands[1];
            // TODO: Add the remaining operators (concat, minus, etc.)
            default:
                return null;
        }
    }

    checkCondition(step, lastResult) {
        const operands = step.operands.map(op => this.resolveOperand(op));
        const sourceValue = this.resolveOperand(step.operands[0]);

        switch (step.operator) {
            case 'gt':
                return sourceValue > operands[1];
            // TODO: Add the remaining operators (eql?, lt?, etc.)
            default:
                return false;
        }
    }

    executeEffect(step, lastResult) {
        const { operator, payload } = step;
        switch (operator) {
            case 'set_state':
                this.component.api.setState(payload);
                break;
            case 'set_state_from_result':
                const value = this.context[payload.result];
                this.component.api.setState({ [payload.state]: value });
                break;
            // TODO: Add the remaining effects (run, dispatch, etc.)
        }
    }

    /**
     * Allows" operand: takes a value from the state, from the temporary context, or uses a static value.
     */
    resolveOperand(operand) {
        if (typeof operand === 'object' && operand !== null) {
            if (operand.value) return operand.value;
            if (operand.state) return this.component.state[operand.state];
            if (operand.result) return this.context[operand.result];
        }
        // If the operand is a simple symbol (for example, :price), we take it from the state.
        if (typeof operand === 'string' || typeof operand === 'symbol') {
            return this.component.state[operand] ?? this.context[operand];
        }
        return operand;
    }
}
