import { registerPlugin } from '@capacitor/core';
const MapsLauncher = registerPlugin('MapsLauncher', {
    web: () => import('./web.js').then(m => new m.MapsLauncherWeb()),
});
export * from './definitions.js';
export { MapsLauncher };
