class PluginManager {
    constructor() {
        this.plugins = [];
    }

    /**
     * Registers a plugin with the plugin manager.
     * @param plugin
     */
    register(plugin) {
        if (!plugin.name) {
            console.error("Tailmix Plugin Error: a plugin must have a name.", plugin);
            return;
        }
        this.plugins.push(plugin);
    }

    /**
     * Connects a component to all registered plugins.
     * @param component
     */
    connect(component) {
        this.plugins.forEach(plugin => {
            if (typeof plugin.connect === 'function') {
                const pluginConfig = component.definition.plugins?.[plugin.name];
                if (pluginConfig) {
                    plugin.connect(component.api, pluginConfig);
                }
            }
        });
    }
}

export {PluginManager};

