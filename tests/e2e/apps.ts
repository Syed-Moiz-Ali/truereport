// App matrix for the TrueReport browser harness.
// Ports are derived from the static server commands in playwright.config.ts.
export const API = process.env.E2E_API_URL || 'http://localhost:8080';

export type AppKey = 'platform' | 'workshop' | 'technician';

export interface AppConfig {
  key: AppKey;
  name: string;
  baseURL: string;
  signInPath: string;
  homePath: string;
  email: string;
  passwordEnv: 'E2E_PLATFORM_PASSWORD' | 'E2E_WORKSHOP_PASSWORD' | 'E2E_TECHNICIAN_PASSWORD';
  emailEnv: 'E2E_PLATFORM_EMAIL' | 'E2E_WORKSHOP_EMAIL' | 'E2E_TECHNICIAN_EMAIL';
}

export const APPS: Record<AppKey, AppConfig> = {
  platform: {
    key: 'platform',
    name: 'Platform Admin',
    baseURL: process.env.E2E_PLATFORM_URL || 'http://127.0.0.1:5301',
    signInPath: '/signin',
    // The platform shell lands on /workshops after sign-in (observed in the
    // running build); /dashboard is reachable from the rail.
    homePath: '/workshops',
    email: 'platform@truereport.test',
    emailEnv: 'E2E_PLATFORM_EMAIL',
    passwordEnv: 'E2E_PLATFORM_PASSWORD',
  },
  workshop: {
    key: 'workshop',
    name: 'Workshop Admin',
    baseURL: process.env.E2E_WORKSHOP_URL || 'http://127.0.0.1:5302',
    signInPath: '/signin',
    homePath: '/workshop',
    email: 'admin.a@truereport.test',
    emailEnv: 'E2E_WORKSHOP_EMAIL',
    passwordEnv: 'E2E_WORKSHOP_PASSWORD',
  },
  technician: {
    key: 'technician',
    name: 'Technician',
    baseURL: process.env.E2E_TECHNICIAN_URL || 'http://127.0.0.1:5303',
    signInPath: '/signin',
    homePath: '/jobs',
    email: 'tech.a@truereport.test',
    emailEnv: 'E2E_TECHNICIAN_EMAIL',
    passwordEnv: 'E2E_TECHNICIAN_PASSWORD',
  },
};

export function appForProject(projectName: string): AppConfig | null {
  if (projectName === 'platform-admin') return APPS.platform;
  if (projectName === 'workshop-admin') return APPS.workshop;
  if (projectName === 'technician') return APPS.technician;
  return null;
}

export function uniqueSuffix(): string {
  return `${Date.now()}-${Math.floor(Math.random() * 10000)}`;
}
