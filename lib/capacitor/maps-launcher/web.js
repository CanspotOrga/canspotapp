import { WebPlugin } from '@capacitor/core';
export class MapsLauncherWeb extends WebPlugin {
    async getAvailableApps() {
        throw this.unimplemented('Not implemented on web.');
    }
    async getDefaultApp() {
        throw this.unimplemented('Not implemented on web.');
    }
    async navigate(_options) {
        throw this.unimplemented('Not implemented on web.');
    }
}
