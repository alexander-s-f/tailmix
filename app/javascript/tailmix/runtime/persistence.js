
export class PersistenceManager {
    constructor(component) {
        this.component = component;
        this.config = component.definition.persistence || {};
        this.types = component.definition.types || {};

        this.listeners = [];
    }

    loadOverrides() {
        const overrides = {};

        for (const [stateName, setting] of Object.entries(this.config)) {
            const strategy = this.getStrategy(setting.type);
            let value = strategy.read(setting.key);

            if (value !== null && value !== undefined) {
                const type = this.types[stateName] || 'string';
                value = this.cast(value, type);

                overrides[stateName] = value;
            }
        }
        return overrides;
    }

    // Called when the state is updated
    save(newStatePatch) {
        for (const [stateName, newValue] of Object.entries(newStatePatch)) {
            const setting = this.config[stateName];
            if (setting) {
                const strategy = this.getStrategy(setting.type);
                strategy.write(setting.key, newValue);
            }
        }
    }

    // Listening for external changes (Back button, URL change, localStorage change in another tab)
    bindListeners() {
        // HASH & QUERY (URL changes)
        const hasUrlState = Object.values(this.config).some(c => ['hash', 'query'].includes(c.type));

        if (hasUrlState) {
            const onPopState = () => {
                const patch = this.loadOverrides();
                if (Object.keys(patch).length > 0) {
                    // Updating the component, but marking it as not to save (avoid loops)
                    this.component.update(patch, { skipPersistence: true });
                }
            };
            window.addEventListener('popstate', onPopState);
            window.addEventListener('hashchange', onPopState);
            this.listeners.push(() => {
                window.removeEventListener('popstate', onPopState);
                window.removeEventListener('hashchange', onPopState);
            });
        }

        // LOCAL STORAGE
        const hasLocalState = Object.values(this.config).some(c => c.type === 'local');
        if (hasLocalState) {
            const onStorage = (e) => {
                // This is simplified logic, ideally, keys should be mapped back to stateName
                const relevantKeys = Object.values(this.config).filter(c => c.type === 'local').map(c => c.key);

                if (relevantKeys.includes(e.key)) {
                    const patch = this.loadOverrides(); // Перечитываем всё
                    this.component.update(patch, { skipPersistence: true });
                }
            };
            window.addEventListener('storage', onStorage);
            this.listeners.push(() => window.removeEventListener('storage', onStorage));
        }
    }

    cast(value, type) {
        if (value === null || value === undefined) return value;

        switch (type) {
            case 'integer':
                return parseInt(value, 10);
            case 'float':
                return parseFloat(value);
            case 'boolean':
                // "true", "1", true -> true
                return (value === 'true' || value === '1' || value === true || value === 1);
            case 'json':
                if (typeof value === 'object') return value;
                try { return JSON.parse(value); } catch(e) { return null; }
            default:
                return String(value);
        }
    }

    disconnect() {
        this.listeners.forEach(cleanup => cleanup());
    }

    getStrategy(type) {
        switch (type) {
            case 'hash': return HashStrategy;
            case 'query': return QueryStrategy;
            case 'local': return LocalStorageStrategy;
            case 'session': return SessionStorageStrategy;
            default: return { read: () => null, write: () => {} };
        }
    }
}

// --- Strategies ---

const HashStrategy = {
    read(key) {
        // We support the #key=value&key2=value2 format
        // If the hash is just a string without =, we consider it the value for the default (or only) key
        const hash = window.location.hash.substring(1); // remove #
        if (!hash) return null;

        // If the hash is not like a query string (no =), and we are looking for a value,
        // we can return the entire hash. Но для надежности лучше всегда использовать ключ-значение.
        const params = new URLSearchParams(hash);
        return params.get(key) || (hash.includes('=') ? null : hash);
    },
    write(key, value) {
        const hash = window.location.hash.substring(1);
        const params = new URLSearchParams(hash.includes('=') ? hash : "");

        if (value) {
            params.set(key, value);
        } else {
            params.delete(key);
        }

        const newHash = params.toString();
        // Use replaceState to avoid spamming the history, or pushState if we want navigation.
        // todo: make configurable
        // Usually, history is desired for tabs.
        if (newHash !== hash) {
            window.history.pushState(null, '', '#' + newHash);
        }
    }
};

const QueryStrategy = {
    read(key) {
        const params = new URLSearchParams(window.location.search);
        return params.get(key);
    },
    write(key, value) {
        const url = new URL(window.location);
        if (value) {
            url.searchParams.set(key, value);
        } else {
            url.searchParams.delete(key);
        }
        window.history.pushState(null, '', url);
    }
};

const LocalStorageStrategy = {
    read(key) {
        try {
            return JSON.parse(window.localStorage.getItem(key));
        } catch(e) {
            return window.localStorage.getItem(key);
        }
    },
    write(key, value) {
        if (value === null || value === undefined) {
            window.localStorage.removeItem(key);
        } else {
            window.localStorage.setItem(key, JSON.stringify(value));
        }
    }
};

const SessionStorageStrategy = {
    read(key) {
        try { return JSON.parse(window.sessionStorage.getItem(key)); } catch(e) { return null; }
    },
    write(key, value) {
        window.sessionStorage.setItem(key, JSON.stringify(value));
    }
};