import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'io.ionic.starter',
  appName: 'example',
  webDir: 'www',
  bundledWebRuntime: false,
  server: {
    androidScheme: "http"
  }
};

export default config;
