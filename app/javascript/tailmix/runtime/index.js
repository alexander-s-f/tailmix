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
        
        // Initialize DevTools Inspector
        DevTools.init();
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
                if ([...m.addedNodes].some(n => n.nodeType === 1 && n.matches?.('[data-tailmix-component]'))) {
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

const DevTools = {
    isAltPressed: false,
    hoveredElement: null,
    highlightOverlay: null,
    inspectorModal: null,

    init() {
        if (typeof document === 'undefined') return;

        document.addEventListener("keydown", (e) => {
            if (e.key === "Alt") {
                this.isAltPressed = true;
                this.enableInspector();
            }
        });

        document.addEventListener("keyup", (e) => {
            if (e.key === "Alt") {
                this.isAltPressed = false;
                this.disableInspector();
            }
        });

        document.addEventListener("click", (e) => {
            if (this.isAltPressed) {
                const target = e.target.closest("[data-tailmix-dev-component]");
                if (target) {
                    e.preventDefault();
                    e.stopPropagation();
                    this.showInspectorModal(target);
                }
            }
        }, true);

        document.addEventListener("mouseover", (e) => {
            if (!this.isAltPressed) return;
            const target = e.target.closest("[data-tailmix-dev-component]");
            if (target) {
                this.hoveredElement = target;
                this.updateHighlight(target);
            } else {
                this.hoveredElement = null;
                this.updateHighlight(null);
            }
        });

        document.addEventListener("mouseout", (e) => {
            if (!this.isAltPressed) return;
            if (this.hoveredElement && !this.hoveredElement.contains(e.relatedTarget)) {
                this.hoveredElement = null;
                this.updateHighlight(null);
            }
        });
    },

    createHighlightOverlay() {
        if (!this.highlightOverlay) {
            this.highlightOverlay = document.createElement("div");
            this.highlightOverlay.style.position = "absolute";
            this.highlightOverlay.style.pointerEvents = "none";
            this.highlightOverlay.style.border = "2px solid rgb(147, 51, 234)";
            this.highlightOverlay.style.backgroundColor = "rgba(147, 51, 234, 0.1)";
            this.highlightOverlay.style.zIndex = "999999";
            this.highlightOverlay.style.boxSizing = "border-box";
            this.highlightOverlay.style.transition = "all 0.1s ease";
            this.highlightOverlay.style.display = "none";
            
            const badge = document.createElement("div");
            badge.style.position = "absolute";
            badge.style.top = "-24px";
            badge.style.left = "0";
            badge.style.backgroundColor = "rgb(147, 51, 234)";
            badge.style.color = "white";
            badge.style.fontSize = "12px";
            badge.style.fontFamily = "monospace";
            badge.style.padding = "2px 6px";
            badge.style.borderRadius = "4px 4px 0 0";
            badge.style.whiteSpace = "nowrap";
            badge.className = "tailmix-dev-badge";
            
            this.highlightOverlay.appendChild(badge);
            document.body.appendChild(this.highlightOverlay);
        }
    },

    updateHighlight(element) {
        if (!element) {
            if (this.highlightOverlay) this.highlightOverlay.style.display = "none";
            return;
        }
        this.createHighlightOverlay();
        const rect = element.getBoundingClientRect();
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        const scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
        
        this.highlightOverlay.style.top = `${rect.top + scrollTop}px`;
        this.highlightOverlay.style.left = `${rect.left + scrollLeft}px`;
        this.highlightOverlay.style.width = `${rect.width}px`;
        this.highlightOverlay.style.height = `${rect.height}px`;
        this.highlightOverlay.style.display = "block";
        
        const compClass = element.getAttribute("data-tailmix-dev-component");
        const compName = compClass.split("::").pop();
        this.highlightOverlay.querySelector(".tailmix-dev-badge").textContent = `${compName} (Option+Click)`;
    },

    showInspectorModal(element) {
        if (!this.inspectorModal) {
            this.inspectorModal = document.createElement("div");
            this.inspectorModal.style.position = "fixed";
            this.inspectorModal.style.bottom = "20px";
            this.inspectorModal.style.right = "20px";
            this.inspectorModal.style.width = "400px";
            this.inspectorModal.style.maxHeight = "500px";
            this.inspectorModal.style.overflowY = "auto";
            this.inspectorModal.style.backgroundColor = "rgba(17, 24, 39, 0.95)";
            this.inspectorModal.style.backdropFilter = "blur(8px)";
            this.inspectorModal.style.border = "1px solid rgba(255, 255, 255, 0.1)";
            this.inspectorModal.style.borderRadius = "12px";
            this.inspectorModal.style.boxShadow = "0 20px 25px -5px rgba(0, 0, 0, 0.5), 0 10px 10px -5px rgba(0, 0, 0, 0.5)";
            this.inspectorModal.style.color = "#f3f4f6";
            this.inspectorModal.style.fontFamily = "system-ui, -apple-system, sans-serif";
            this.inspectorModal.style.zIndex = "9999999";
            this.inspectorModal.style.boxSizing = "border-box";
            this.inspectorModal.style.padding = "16px";
            this.inspectorModal.style.transition = "all 0.3s ease";
            document.body.appendChild(this.inspectorModal);
        }
        
        this.inspectorModal.style.display = "block";
        this.inspectorModal.style.opacity = "1";
        
        const compClass = element.getAttribute("data-tailmix-dev-component") || "Unknown";
        const compName = compClass.split("::").pop();
        const source = element.getAttribute("data-tailmix-dev-source") || "Unknown";
        
        let variantsList = [];
        try {
            variantsList = JSON.parse(element.getAttribute("data-tailmix-dev-variants") || "[]");
        } catch(e) {}
        
        let currentVariants = {};
        try {
            currentVariants = JSON.parse(element.getAttribute("data-tailmix-dev-current-variants") || "{}");
        } catch(e) {}

        let currentStates = {};
        try {
            currentStates = JSON.parse(element.getAttribute("data-tailmix-dev-state") || "{}");
        } catch(e) {}
        
        const tailmixInstance = window.Tailmix?.instances?.get(element);
        if (tailmixInstance && tailmixInstance.state) {
            currentStates = tailmixInstance.state;
        }

        this.inspectorModal.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 8px;">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="display: inline-block; width: 8px; height: 8px; border-radius: 50%; background-color: rgb(147, 51, 234); box-shadow: 0 0 8px rgb(147, 51, 234);"></span>
                    <span style="font-weight: 700; font-size: 16px; color: #fff;">${compName}</span>
                </div>
                <button id="tailmix-inspector-close" style="background: none; border: none; color: #9ca3af; cursor: pointer; font-size: 18px; padding: 4px;">&times;</button>
            </div>
            
            <div style="font-size: 13px; margin-bottom: 14px;">
                <div style="color: #9ca3af; margin-bottom: 4px;">Class:</div>
                <div style="font-family: monospace; background: rgba(0,0,0,0.3); padding: 4px 8px; border-radius: 4px; color: #a5b4fc; word-break: break-all;">${compClass}</div>
            </div>

            <div style="font-size: 13px; margin-bottom: 14px;">
                <div style="color: #9ca3af; margin-bottom: 4px; display: flex; justify-content: space-between; align-items: center;">
                    <span>Source File:</span>
                    <span id="copy-status" style="color: rgb(147, 51, 234); font-size: 11px; display: none;">Copied!</span>
                </div>
                <div id="tailmix-inspector-copy" style="font-family: monospace; background: rgba(0,0,0,0.3); padding: 6px 8px; border-radius: 4px; color: #34d399; cursor: pointer; display: flex; justify-content: space-between; align-items: center;" title="Click to copy path">
                    <span style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 320px;">${source}</span>
                    <svg style="width: 14px; height: 14px; fill: currentColor; flex-shrink: 0;" viewBox="0 0 24 24"><path d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/></svg>
                </div>
            </div>

            <div style="font-size: 13px; margin-bottom: 14px;">
                <div style="color: #9ca3af; margin-bottom: 4px;">Variants & Current Values:</div>
                <div style="display: flex; flex-direction: column; gap: 4px;">
                    ${variantsList.length > 0 ? variantsList.map(v => `
                        <div style="display: flex; justify-content: space-between; background: rgba(0,0,0,0.2); padding: 4px 8px; border-radius: 4px;">
                            <span style="color: #fca5a5; font-family: monospace;">${v}</span>
                            <span style="color: #fcd34d; font-family: monospace;">:${currentVariants[v] || 'default'}</span>
                        </div>
                    `).join('') : '<div style="color: #6b7280; font-style: italic;">No variants defined</div>'}
                </div>
            </div>

            <div style="font-size: 13px; margin-bottom: 14px;">
                <div style="color: #9ca3af; margin-bottom: 4px;">Reactive State:</div>
                <div style="font-family: monospace; background: rgba(0,0,0,0.3); padding: 6px 8px; border-radius: 4px; color: #6ee7b7;">
                    ${Object.keys(currentStates).length > 0 ? JSON.stringify(currentStates, null, 2).replace(/\n/g, '<br>').replace(/\s/g, '&nbsp;') : '<span style="color: #6b7280; font-style: italic;">Empty / Default</span>'}
                </div>
            </div>

            <div style="border-top: 1px solid rgba(255,255,255,0.1); padding-top: 10px; margin-top: 10px;">
                <div style="font-weight: 600; font-size: 13px; color: #fff; margin-bottom: 6px;">Override & Customization Patterns:</div>
                <div style="display: flex; flex-direction: column; gap: 6px; font-size: 11px;">
                    <div style="background: rgba(147, 51, 234, 0.1); border-left: 2px solid rgb(147, 51, 234); padding: 6px; border-radius: 0 4px 4px 0;">
                        <span style="font-weight: 700; color: #fff; display: block; margin-bottom: 2px;">1. Zero-code customization</span>
                        Pass Tailwind classes: <code>badge :active, class: "my-custom-margin border shadow"</code>
                    </div>
                    <div style="background: rgba(52, 211, 153, 0.1); border-left: 2px solid rgb(52, 211, 153); padding: 6px; border-radius: 0 4px 4px 0;">
                        <span style="font-weight: 700; color: #fff; display: block; margin-bottom: 2px;">2. OOP Inheritance</span>
                        Subclass the component: <code style="display:block; margin-top:2px;">class MyBadge &lt; ${compClass}<br>&nbsp;&nbsp;def build(*)<br>&nbsp;&nbsp;&nbsp;&nbsp;super<br>&nbsp;&nbsp;&nbsp;&nbsp;add_class("shadow")<br>&nbsp;&nbsp;end<br>end</code>
                    </div>
                </div>
            </div>
        `;

        document.getElementById("tailmix-inspector-close").addEventListener("click", () => {
            this.inspectorModal.style.display = "none";
        });

        document.getElementById("tailmix-inspector-copy").addEventListener("click", () => {
            navigator.clipboard.writeText(source).then(() => {
                const s = document.getElementById("copy-status");
                s.style.display = "inline";
                setTimeout(() => s.style.display = "none", 1500);
            });
        });
    },

    enableInspector() {
        document.body.style.cursor = "help";
    },

    disableInspector() {
        document.body.style.cursor = "default";
        if (this.highlightOverlay) this.highlightOverlay.style.display = "none";
    }
};

if (typeof window !== 'undefined') {
    window.Tailmix = Object.assign(window.Tailmix || {}, Tailmix);

    document.addEventListener("DOMContentLoaded", () => Tailmix.start());
    document.addEventListener("turbo:load", () => Tailmix.start());
}

export default Tailmix;