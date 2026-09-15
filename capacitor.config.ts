import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.altakhfeedalsh.app',
  appName: 'التخفيض الصح',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
    cleartext: true,
    allowNavigation: [
      'whats.alattab.site',
      '*.alattab.site',
      'api.alattab.site',
      'ais-dev-jwezxmrlo3sf46na3re4ls-208711455202.europe-west1.run.app'
    ]
  },
  android: {
    allowMixedContent: true,
    captureInput: true,
    webContentsDebuggingEnabled: true
  }
};

export default config;
