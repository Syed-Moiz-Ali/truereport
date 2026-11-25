/// Sample content for the jobs-module design previews.
///
/// Throwaway: this file exists so the three direction previews render the same
/// realistic job instead of lorem ipsum. It is deleted once a direction ships.
library;

enum PreviewScreen { queue, job }

class PreviewJob {
  const PreviewJob({
    required this.reference,
    required this.vehicle,
    required this.plate,
    required this.customer,
    required this.when,
    required this.status,
    required this.done,
    required this.total,
    this.overdue = false,
    this.current = false,
  });

  final String reference;
  final String vehicle;
  final String plate;
  final String customer;
  final String when;
  final String status;
  final int done;
  final int total;
  final bool overdue;
  final bool current;
}

class PreviewItem {
  const PreviewItem(
    this.number,
    this.label, {
    this.instruction = '',
    this.safety = false,
    this.photo = false,
    this.result,
  });

  final int number;
  final String label;
  final String instruction;
  final bool safety;
  final bool photo;

  /// Pass | Advisory | Fail | null
  final String? result;
}

class PreviewSection {
  const PreviewSection(this.name, this.items);

  final String name;
  final List<PreviewItem> items;

  int get done => items.where((item) => item.result != null).length;
  int get total => items.length;
  PreviewItem? get next {
    for (final item in items) {
      if (item.result == null) return item;
    }
    return null;
  }
}

const previewVehicle = 'Toyota Land Cruiser 2023';
const previewPlate = 'AUD-354626';
const previewReference = 'JOB-659515E0';
const previewCustomer = 'Ahmed Al Mansoori';

const previewJobs = <PreviewJob>[
  PreviewJob(
    reference: 'JOB-659515E0',
    vehicle: previewVehicle,
    plate: previewPlate,
    customer: previewCustomer,
    when: '11:50',
    status: 'In progress',
    done: 9,
    total: 30,
    current: true,
  ),
  PreviewJob(
    reference: 'JOB-098B4B25',
    vehicle: 'Nissan Patrol 2022',
    plate: 'DXB-88213',
    customer: 'Mariam Al Suwaidi',
    when: '13:30',
    status: 'Assigned',
    done: 0,
    total: 30,
  ),
  PreviewJob(
    reference: 'JOB-30CEECAC',
    vehicle: 'Toyota Corolla 2024',
    plate: 'AUH-55120',
    customer: 'Omar Haddad',
    when: '15:00',
    status: 'Assigned',
    done: 0,
    total: 30,
  ),
  PreviewJob(
    reference: 'JOB-AC8DF6C9',
    vehicle: 'Ford F-150 2021',
    plate: 'SHJ-90211',
    customer: 'Sara Khan',
    when: '23 Nov',
    status: 'Assigned',
    done: 6,
    total: 30,
    overdue: true,
  ),
];

const previewSections = <PreviewSection>[
  PreviewSection('Powertrain & Mechanical', [
    PreviewItem(
      1,
      'Engine oil condition',
      result: 'Pass',
      instruction:
          'Oil level between MIN/MAX; amber or brown colour; normal viscosity.',
    ),
    PreviewItem(
      2,
      'Engine air filter',
      result: 'Pass',
      instruction:
          'Clean filter pleats; intact housing seals; clean MAF housing.',
    ),
    PreviewItem(
      3,
      'Transmission fluid',
      result: 'Pass',
      instruction: 'Pink/red or clear fluid; no burnt odour; no gear shudder.',
    ),
    PreviewItem(
      4,
      'Cooling system',
      result: 'Advisory',
      instruction: 'Holds 15 psi for 5 minutes; clean coolant; flexible hoses.',
      safety: true,
    ),
    PreviewItem(
      5,
      'Drive belts',
      result: 'Pass',
      instruction: 'No cracks; no pulley chirp; tensioner aligned.',
    ),
    PreviewItem(
      6,
      'Exhaust system',
      result: 'Pass',
      instruction: 'No exhaust leaks; catalyst delta temperature above 50 C.',
    ),
  ]),
  PreviewSection('Suspension, Steering & Underbody', [
    PreviewItem(
      7,
      'Front shocks',
      result: 'Pass',
      instruction: 'No leaks; even rebound; mounts intact.',
    ),
    PreviewItem(
      8,
      'Rear dampers',
      result: 'Pass',
      instruction: 'No leaks; even rebound; mounts intact.',
    ),
    PreviewItem(
      9,
      'Steering rack',
      result: 'Pass',
      instruction: 'No play; boots intact; no leaks.',
    ),
    PreviewItem(
      10,
      'Front brake pads',
      safety: true,
      photo: true,
      instruction: 'Measure pad thickness at the thinnest point. Photograph the pad and the disc face.',
    ),
    PreviewItem(
      11,
      'Tyre condition & pressures',
      photo: true,
      instruction: 'Tread depth above legal minimum; no sidewall damage; pressures to spec.',
    ),
  ]),
  PreviewSection('Braking Systems & Tyres', [
    PreviewItem(
      12,
      'Front discs',
      safety: true,
      instruction: 'No deep scoring; minimum 28 mm.',
    ),
    PreviewItem(
      13,
      'Rear discs',
      instruction: 'No deep scoring; minimum 18 mm.',
    ),
    PreviewItem(
      14,
      'Brake fluid',
      safety: true,
      instruction: 'Moisture below 3%; level at MAX.',
    ),
    PreviewItem(
      15,
      'Parking brake travel',
      instruction: '5–7 clicks; holds on a slope.',
    ),
    PreviewItem(
      16,
      'Brake lines',
      safety: true,
      instruction: 'No corrosion; no chafing.',
    ),
  ]),
  PreviewSection('Electrical, Battery & Diagnostics', [
    PreviewItem(
      17,
      'Battery health',
      instruction: 'Above 12.4 V at rest; terminals clean.',
    ),
    PreviewItem(
      18,
      'Charging system',
      instruction: '13.8–14.8 V at idle with loads on.',
    ),
    PreviewItem(
      19,
      'Fault codes',
      instruction: 'Read all modules; clear only after repair.',
    ),
    PreviewItem(20, 'Lighting', instruction: 'All external lamps operate.'),
    PreviewItem(
      21,
      'Horn & wipers',
      instruction: 'Horn works; blades clear; washers spray.',
    ),
  ]),
  PreviewSection('Body, Glass & Interior', [
    PreviewItem(
      22,
      'Body panels',
      instruction: 'No dents, rust or mismatched paint.',
    ),
    PreviewItem(
      23,
      'Glass',
      instruction: 'No chips in the driver\'s line of sight.',
    ),
    PreviewItem(
      24,
      'Seatbelts',
      safety: true,
      instruction: 'Retract; lock under load; no fraying.',
    ),
    PreviewItem(
      25,
      'Interior trim',
      instruction: 'No loose trim; all controls present.',
    ),
    PreviewItem(
      26,
      'Cabin filter',
      instruction: 'Clean; no odour; housing sealed.',
    ),
  ]),
  PreviewSection('Road Test & Dynamic Performance', [
    PreviewItem(
      27,
      'Braking performance',
      safety: true,
      instruction: 'Straight stop; no pull; no noise.',
    ),
    PreviewItem(
      28,
      'Steering feel',
      instruction: 'Centres correctly; no vibration.',
    ),
    PreviewItem(
      29,
      'Transmission shift',
      instruction: 'Smooth up and down; no flare.',
    ),
    PreviewItem(
      30,
      'Suspension noise',
      instruction: 'No knocks over speed humps.',
    ),
  ]),
];

const previewCurrentItem = PreviewItem(
  10,
  'Front brake pads',
  safety: true,
  photo: true,
  instruction: 'Measure pad thickness at the thinnest point. Photograph the pad and the disc face.',
);
