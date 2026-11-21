import { APIRequestContext, expect } from '@playwright/test';
import { API, uniqueSuffix } from '../apps';

export interface Login {
  token: string;
  userId: string;
}

export async function loginAs(
  ctx: APIRequestContext,
  email: string,
  password: string,
): Promise<Login> {
  const response = await ctx.post(`${API}/api/v1/auth/login`, {
    data: { email, password },
  });
  expect(response.ok(), `login ${email}`).toBeTruthy();
  const body = await response.json();
  return { token: body.accessToken, userId: body.user.id };
}

export function auth(token: string): Record<string, string> {
  return { Authorization: `Bearer ${token}` };
}

export interface SeededJob {
  id: string;
  reference: string;
  status: string;
  assignedTechnicianId: string;
  vehiclePlate: string;
}

export async function seedJob(
  ctx: APIRequestContext,
  workshopToken: string,
  overrides: Record<string, unknown> = {},
): Promise<SeededJob> {
  const headers = auth(workshopToken);
  const templates = await ctx.get(`${API}/api/v1/workshop/template-versions/available`, {
    headers,
  });
  expect(templates.ok()).toBeTruthy();
  const templateList = (await templates.json()) as Array<{ versionId: string }>;
  expect(templateList.length, 'workshop needs a published template').toBeGreaterThan(0);

  const staff = await ctx.get(`${API}/api/v1/workshop/staff`, { headers });
  expect(staff.ok()).toBeTruthy();
  const staffList = (await staff.json()) as Array<{ userId: string; role: string }>;
  const technician = staffList.find((member) => member.role === 'TECHNICIAN');

  const suffix = uniqueSuffix().replace(/[^0-9]/g, '').slice(-6);
  const payload = {
    templateVersionId: templateList[0].versionId,
    customerName: `Audit Customer ${suffix}`,
    customerPhone: `+97150${suffix.padEnd(7, '0').slice(0, 7)}`,
    customerEmail: `audit.${suffix}@example.test`,
    vehicleVin: `JTMBY7AJ9${suffix.padStart(8, '0').slice(0, 8)}`,
    vehicleMake: 'Toyota',
    vehicleModel: 'Land Cruiser',
    vehicleYear: 2023,
    vehiclePlate: `AUD-${suffix}`,
    odometerValue: 42850,
    odometerUnit: 'KM',
    transmission: 'AUTOMATIC',
    fuelType: 'PETROL',
    preferredLanguage: 'en',
    assignedTechnicianId: technician?.userId,
    consentGranted: true,
    // The technician queue is day-scoped; a job without a schedule is invisible
    // there. Scheduling it today keeps status ASSIGNED and makes it reachable.
    scheduledAt: new Date().toISOString().slice(0, 19),
    ...overrides,
  };

  const response = await ctx.post(`${API}/api/v1/workshop/jobs`, {
    headers: { ...headers, 'Idempotency-Key': `e2e-${suffix}-${Date.now()}` },
    data: payload,
  });
  expect(response.ok(), `create job: ${response.status()} ${await response.text()}`).toBeTruthy();
  const created = (await response.json()) as Omit<SeededJob, 'vehiclePlate'>;
  return { ...created, vehiclePlate: payload.vehiclePlate };
}

export async function getJob(
  ctx: APIRequestContext,
  token: string,
  jobId: string,
): Promise<Record<string, unknown>> {
  const response = await ctx.get(`${API}/api/v1/workshop/jobs/${jobId}`, {
    headers: auth(token),
  });
  expect(response.ok()).toBeTruthy();
  return (await response.json()) as Record<string, unknown>;
}

export async function cancelJobViaApi(
  ctx: APIRequestContext,
  token: string,
  jobId: string,
  reason = 'E2E cleanup',
): Promise<void> {
  const current = await getJob(ctx, token, jobId);
  const response = await ctx.post(`${API}/api/v1/workshop/jobs/${jobId}/cancel`, {
    headers: auth(token),
    data: { reason, version: current.version },
  });
  expect(response.ok(), `cancel ${jobId}`).toBeTruthy();
}
