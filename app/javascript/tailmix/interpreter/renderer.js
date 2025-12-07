import { Scope } from './scope';
import { Evaluator } from './evaluator';

export class Renderer {
    static calculate(elementDef, state, param, element) {
        return new Renderer(elementDef, state, param, element).calculate();
    }

    constructor(elementDef, state, param, element) {
        this.definition = elementDef;
        this.scope = new Scope(state, param, element);
        this.evaluator = new Evaluator(this.scope);
        this.extraAttributes = param; // Ad-hoc params
    }

    calculate() {
        // 1. Base (Static attributes)
        const staticAttrs = this.definition.static || {};

        const acc = {
            classes: new Set(staticAttrs.class ? staticAttrs.class.split(/\s+/) : []),
            data: {},
            aria: {},
            other: { ...staticAttrs } // ID, type, etc.
        };
        delete acc.other.class;

        // 2. Apply Rules
        if (this.definition.rules) {
            for (const rule of this.definition.rules) {
                this.processRule(rule, acc);
            }
        }

        // 3. Merge Ad-hoc attributes (Param)
        this.mergeExtraAttributes(acc);

        return acc;
    }

    processRule(rule, acc) {
        const op = rule[0];

        switch (op) {
            case 'style': {
                // [:style, condition, true_eff, false_eff]
                const [_, condition, trueEff, falseEff] = rule;
                if (this.evaluator.evaluate(condition)) {
                    this.applyEffect(trueEff, acc);
                } else {
                    this.applyEffect(falseEff, acc);
                }
                break;
            }
            case 'match': {
                // [:match, subject, cases, default]
                const [_, subject, cases, defaultEff] = rule;
                const val = this.evaluator.evaluate(subject);

                const key = String(val);

                if (cases && Object.prototype.hasOwnProperty.call(cases, key)) {
                    this.applyEffect(cases[key], acc);
                } else if (defaultEff) {
                    this.applyEffect(defaultEff, acc);
                }
                break;
            }
        }
    }

    applyEffect(effect, acc) {
        if (!effect) return;

        // effect = { "c": "class string", "d": { key: expr }, "a": { key: expr } }

        // Classes
        if (effect.c) {
            const classes = effect.c.split(/\s+/);
            for (const cls of classes) {
                if (cls) acc.classes.add(cls);
            }
        }

        // Data (key "d")
        if (effect.d) {
            for (const [key, expr] of Object.entries(effect.d)) {
                acc.data[key] = this.evaluator.evaluate(expr);
            }
        }

        // Aria (key "a")
        if (effect.a) {
            for (const [key, expr] of Object.entries(effect.a)) {
                acc.aria[key] = this.evaluator.evaluate(expr);
            }
        }
    }

    mergeExtraAttributes(acc) {
        for (const [key, value] of Object.entries(this.extraAttributes)) {
            if (key === 'class') {
                const classes = String(value).split(/\s+/);
                for (const cls of classes) if (cls) acc.classes.add(cls);
            } else if (key.startsWith('data-')) {
                const dataKey = key.replace(/^data-/, '');
                acc.data[dataKey] = value;
            } else if (key.startsWith('aria-')) {
                const ariaKey = key.replace(/^aria-/, '');
                acc.aria[ariaKey] = value;
            } else if (key !== 'root') {
                // Overwriting static attributes (id, type)
                acc.other[key] = value;
            }
        }
    }
}