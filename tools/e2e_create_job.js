const API = 'http://127.0.0.1:8080';
const VERSION_ID = '01a1f9dd-dd65-7a6e-9468-6c350d415df2';

async function call(token, method, path, body) {
  const response = await fetch(`${API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'X-Client': 'workshop_admin',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${method} ${path} -> ${response.status} ${text.slice(0, 400)}`);
  return text ? JSON.parse(text) : null;
}

(async () => {
  const login = await fetch(`${API}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin.a@truereport.test', password: 'Truereport#Local123' }),
  });
  const { accessToken: token } = await login.json();

  const staff = await call(token, 'GET', '/api/v1/workshop/staff');
  const rows = staff.items ?? staff;
  const technician = rows.find((row) => (row.email ?? '').includes('tech.a'));
  console.log('technician:', technician?.id);

  const job = await call(token, 'POST', '/api/v1/workshop/jobs', {
    templateVersionId: VERSION_ID,
    customerName: 'Full Flow Customer',
    customerPhone: '+971500000077',
    customerEmail: 'fullflow@example.com',
    vehicleMake: 'Toyota',
    vehicleModel: 'Land Cruiser',
    vehicleYear: 2025,
    vehicleVin: 'JTMHV05J204123456',
    vehiclePlate: 'E2E 300',
    odometerValue: 9000,
    odometerUnit: 'KM',
    transmission: 'AUTOMATIC',
    fuelType: 'PETROL',
    preferredLanguage: 'en',
    scheduledAt: new Date().toISOString().slice(0, 19),
    assignedTechnicianId: technician?.id,
    consentGranted: true,
  });
  console.log('job:', job.reference, job.id, job.status, 'consent=', job.consentGranted);
})();
