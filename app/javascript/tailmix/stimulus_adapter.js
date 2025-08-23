import { findElement as findElementByAttribute } from './finder';
import { applyCommand } from './mutator';

/**
 * @param {object} params
 * @param {object} params.config
 * @param {StimulusController} params.controller
 */
export function runFromStimulus({ config, controller }) {
    if (!config?.mutations) {
        console.error("Invalid Tailmix config:", config);
        return;
    }

    for (const elementName in config.mutations) {
        const targetElement = findElement(elementName, controller);

        if (!targetElement) {
            console.warn(`Tailmix: Element "${elementName}" not found.`);
            continue;
        }

        const commands = config.mutations[elementName];

        for (const command of commands) {
            applyCommand(targetElement, command);
        }
    }
}

function findElement(name, controller) {
    const targetName = `${name}Target`;
    if (controller[targetName]) {
        return controller[targetName];
    }
    return findElementByAttribute(controller.element, name);
}