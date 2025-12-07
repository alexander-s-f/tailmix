import { Component } from './component';

var globalNamespace = (typeof window !== "undefined" && window.Tailmix) ? window.Tailmix : {};

const Tailmix = {
    definitions: globalNamespace.definitions || {},

    instances: new WeakMap(),
    booted: false,
    observer: null,

    start() {
        if (this.booted) return;
        this.booted = true;

        if (window.Tailmix?.definitions) {
            Object.assign(this.definitions, window.Tailmix.definitions);
        }

        this.boot();
        this.observe();
        this.log('info', `Started with ${Object.keys(this.definitions).length} definitions`);
    },

    stop() {
        if (!this.booted) return;
        this.observer?.disconnect();
        booted = false;
        this.log('info', 'Stopped');
    },

    log(level, ...args) {
        if (window.TAILMIX_DEBUG) {
            // levels: debug/info/warn/error
            console[level === 'debug' ? 'log' : level]?.('[Tailmix]', ...args);
        }
    },

    observe() {
        this.observer = new MutationObserver((mutations) => {
            let shouldBoot = false;
            for (const m of mutations) {
                if ([...m.addedNodes].some(n => n.nodeType === 1 && n.matches?.('[data-tailmix]'))) {
                    shouldBoot = true; break;
                }
            }
            if (shouldBoot) this.boot();
        });
        this.observer.observe(document.documentElement, { childList: true, subtree: true });
    },

    boot(root = document) {
        const componentRoots = root.querySelectorAll('[data-tailmix-component]');
        componentRoots.forEach(element => {
            if (this.instances.has(element)) return;

            const name = element.dataset.tailmixComponent;
            const definition = this.definitions[name];

            if (definition) {
                const instance = new Component(element, definition);
                this.instances.set(element, instance);
            } else {
                console.warn(`[Tailmix] Definition for "${name}" not found.`);
            }
        });
    },
};

if (typeof window !== 'undefined') {
    window.Tailmix = Object.assign(window.Tailmix || {}, Tailmix);

    document.addEventListener("DOMContentLoaded", () => Tailmix.start());
    document.addEventListener("turbo:load", () => Tailmix.start());
}

export default Tailmix;