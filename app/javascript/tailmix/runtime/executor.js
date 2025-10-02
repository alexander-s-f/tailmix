import { Scope } from './scope';
import { ExpressionEvaluator } from './expression_evaluator';

export class Executor {
    /**
     * Executes the render program for an element.
     * @param {Array} program - The compiled "render program".
     * @param {Scope} componentScope - The root scope of the component.
     * @param {Object} withData - Render-time parameters (from ui.element(...)).
     */
    execute(program, componentScope, withData = {}) {
        let attributeSet = {
            classes: new Set(),
            data: {},
            other: {}
        };

        componentScope.inNewScope(elementScope => {
            elementScope.define('param', withData);
            const evaluator = new ExpressionEvaluator(elementScope); // <-- USE

            for (const instruction of program) {
                const [opcode, args] = instruction;
                attributeSet = this.executeInstruction(opcode, args, attributeSet, evaluator);
            }
        }, {}); // Pass empty hash for local vars

        return attributeSet;
    }

    executeInstruction(opcode, args, set, evaluator) {
        switch (opcode) {
            case 'define_var': {
                const value = evaluator.evaluate(args.expression);
                evaluator.scope.define(args.name, value); // Define in the current scope
                return set;
            }
            case 'evaluate_and_apply_classes':
                return this.applyClasses(set, args, evaluator);
            case 'evaluate_and_apply_attribute':
                return this.applyAttribute(set, args, evaluator);
            case 'setup_model_binding':
                return this.applyModelBinding(set, args, evaluator);
            // ... other instructions
        }
        return set;
    }

    // --- Instruction Implementations (Unchanged) ---
    applyClasses(set, args, evaluator) {
        const value = evaluator.evaluate(args.condition);
        const classesToApply = args.variants[value];
        if (!classesToApply || classesToApply.length === 0) return set;
        const newClasses = new Set([...set.classes, ...classesToApply]);
        return { ...set, classes: newClasses };
    }

    applyAttribute(set, args, evaluator) {
        const value = evaluator.evaluate(args.expression);
        if (value === null || value === undefined) return set;
        const newOther = { ...set.other };
        if (args.is_content) {
            newOther.content = value;
        } else {
            newOther[args.attribute] = value;
        }
        return { ...set, other: newOther };
    }

    applyModelBinding(set, args, evaluator) {
        const targetPath = args.target.slice(1);
        const statePath = args.state.slice(1);
        const attributeName = targetPath.join('-');
        const stateKey = statePath[0];
        const value = evaluator.evaluate(args.state);
        const newOther = { ...set.other, [attributeName]: value };
        const newData = {
            ...set.data,
            'data-tailmix-model-attr': attributeName,
            'data-tailmix-model-state': stateKey,
            'data-tailmix-model-event': args.options?.on || 'input'
        };
        return { ...set, other: newOther, data: newData };
    }
}
