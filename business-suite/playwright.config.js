import { defineConfig, devices } from '@playwright/test';

const liveBaseURL = process.env.E2E_BASE_URL;

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  reporter: 'list',
  use: {
    baseURL: liveBaseURL || 'http://127.0.0.1:4173',
    trace: 'retain-on-failure',
    ...devices['Desktop Chrome'],
  },
  webServer: liveBaseURL ? undefined : {
    command: 'npm run preview -- --host 127.0.0.1',
    url: 'http://127.0.0.1:4173',
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
