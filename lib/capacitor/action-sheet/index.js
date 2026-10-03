import { registerPlugin } from '@capacitor/core';
const ActionSheet = registerPlugin('ActionSheet', {
    web: () => import('./web.js').then((m) => new m.ActionSheetWeb()),
});
export * from './definitions.js';
export { ActionSheet };
