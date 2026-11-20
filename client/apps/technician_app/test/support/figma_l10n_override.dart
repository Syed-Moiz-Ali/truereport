import 'package:l10n/ui_strings.dart';

/// Test-only Figma-text overrides.
///
/// The F2-A fidelity fixtures compare production widgets against the Figma
/// mock pixel-for-pixel. Figma sample wording (e.g. `TechInspect`,
/// `David Vance`, `Renault Megane 3`, `Bay 04`) must therefore render in
/// tests but must never ship in `lib/`.
///
/// Figma wording that is *data* (names, VINs, plates) travels through the
/// normal product model fields ([figmaJobs], [figmaJob], [figmaChecklist]).
/// Figma wording that is *chrome copy* is supplied here: [FigmaTestStrings]
/// documents every sample string, and [figmaMessageOverrides] serves it as
/// backend-keyed message templates so production widgets render Figma text
/// without any `figmaText` switch in `lib/`.
///
/// Usage: pump the screen with [figmaStrings] installed in a [UiStringsScope]
/// (see `f2aHost`). English only.
abstract final class FigmaTestStrings {
  // Login (auth/SignInView reads these through UiStrings).
  static const brand = 'TechInspect';
  static const tagline = 'Vehicle Condition & Fleet Diagnostics';
  static const forgotPassword = 'Forgot password?';
  static const signIn = 'Sign In';
  static const requestId = 'Request ID';
  static const needAccess = 'Need technician access?';
  static const isoSecurity = 'ISO 27001 Certified Fleet Security';

  // Queue chrome.
  static const shiftAndBay = 'SHIFT 1 â€¢ BAY A';
  static const onlineSync = 'LIVE\nSYNC';
  static const intakeTab = 'Intake';
  static const fleetTab = 'Fleet';
  // NOTE: `statusInProgress` is intentionally NOT overridden. The Figma
  // mock shows "Avg. turnover" in the assigned-jobs snapshot card, but that
  // card label is status-derived product logic; serving Figma wording here
  // would corrupt the inspection-hub status pill ("IN PROGRESS"), which the
  // geometry gate asserts. The delta is recorded in the fidelity report.
  static const avgTurnover = 'Avg. turnover';
  static const scanVin = 'Scan New VIN Tag';
  static const shiftActive = 'SHIFT ACTIVE';
  static const bayPill = 'Bay 04';
  static const caughtUp = 'You are all caught up!';
  static const noJobsBody =
      'No pending vehicle inspections assigned\nto you today.';
  static const refreshQueue = 'Refresh Queue';
  static const passRate = '100% Pass Rate';

  // Job intake (status-derived pills stay product logic; see README below).
  static const vehicleInfo = 'Vehicle Info';
  static const primaryOwner = 'Primary Owner';
  static const jobReady = 'Pre-Inspection Ready';
  static const startInspection = 'Start Inspection';

  // Consent.
  static const consentSteps = 'STEP 4 OF 4 \u2022 FINAL SIGN-OFF';
  static const authorizations = 'Authorizations';
  static const consentIntro =
      'Review compliance permissions and provide\ncustomer digital sign-off.';
  static const allowPdf = 'Allow PDF sharing';
  static const allowPdfBody = 'Send detailed diagnostic report via email';
  static const roadTest = 'Customer road test consent';
  static const roadTestBody =
      'Authorize certified technician dynamic evaluation';
  static const dataStorage = 'Data storage authorization';
  static const dataStorageBody =
      'Encrypt telemetry logs and secure fleet cloud backups';
  static const digitalSignature = 'Digital Signature';
  static const signHint = 'Sign with finger or stylus';
  static const signAbove = 'Sign Above Line';
  static const saveConsent = 'Save Consent';

  // Equipment.
  static const setupKicker = 'PRE-INSPECTION SETUP';
  static const verifiedPill = '1 of 4 Verified';
  static const requiredEquipment = 'Required Equipment';
  static const equipmentIntro =
      'Ensure all diagnostic hardware is calibrated and\npaired before launching bay intake.';
  static const stationStandards = 'Fleet Station Standards';
  static const stationStandardsBody =
      'ISO-9001 certified diagnostic requirements';

  // Inspection hub.
  static const hubTitle = 'Intake Hub';
  static const passedPill = 'Passed';
  static const actionItems = 'Action Items';
  static const modulesTitle = 'Inspection Modules';
  static const queued = 'Queued';

  /// In-queue pill product copy renders `{count} in queue`; the Figma mock
  /// capitalises it as `N In Queue`.
  static String inQueue(int count) => '$count In Queue';

  /// Module footer for a finished module; the Figma mock appends `Done`.
  /// Only finished modules used this wording, so the override serves it for
  /// every count pair (see `figma_l10n_override` notes in f2a_views.dart).
  static String checksDone(int done, int total) => '$done/$total Done';
}

/// Backend-keyed Figma copy. Every other key falls through to the real
/// English bundle served by the backend catalog.
const Map<String, String> figmaMessageOverrides = <String, String>{
  'appTitle': FigmaTestStrings.brand,
  'technicianSignInTagline': FigmaTestStrings.tagline,
  'technicianPasswordHelp': FigmaTestStrings.forgotPassword,
  'signInButton': FigmaTestStrings.signIn,
  'technicianContactAdmin': FigmaTestStrings.requestId,
  'technicianNeedTechnicianAccess': FigmaTestStrings.needAccess,
  'technicianSecurityLine': FigmaTestStrings.isoSecurity,
  'technicianShiftToday': FigmaTestStrings.shiftAndBay,
  'technicianOnlineSync': FigmaTestStrings.onlineSync,
  'technicianJobIntake': 'INTAKE PHASE',
  'statusAssigned': 'Ready for Check',
  'technicianJobsTitle': FigmaTestStrings.intakeTab,
  'statusFinalized': FigmaTestStrings.fleetTab,
  'technicianJobsInQueue': '{count} In Queue',
  'walkInJob': FigmaTestStrings.scanVin,
  'technicianInspectionQueue': 'Inspection Queue',
  'technicianQueueEmpty': FigmaTestStrings.shiftActive,
  'technicianJobsCount': FigmaTestStrings.bayPill,
  'technicianAllCaughtUp': FigmaTestStrings.caughtUp,
  'technicianNoJobsBody': FigmaTestStrings.noJobsBody,
  'technicianRefreshQueue': FigmaTestStrings.refreshQueue,
  'technicianCoverageOnly': FigmaTestStrings.passRate,
  'technicianWelcomeBack': 'Welcome back,',
  'technicianAssignedToday': 'Assigned today',
  'technicianVehicleInfo': FigmaTestStrings.vehicleInfo,
  'technicianPhone': 'Phone Number',
  'technicianCustomerChip': FigmaTestStrings.primaryOwner,
  'technicianJobDetailsReady': FigmaTestStrings.jobReady,
  'startInspection': FigmaTestStrings.startInspection,
  'technicianConsentStep': FigmaTestStrings.consentSteps,
  'consent': FigmaTestStrings.authorizations,
  'technicianConsentIntro': FigmaTestStrings.consentIntro,
  'consentPublicLink': FigmaTestStrings.allowPdf,
  'technicianConsentPublicLinkBody': FigmaTestStrings.allowPdfBody,
  'consentProcessing': FigmaTestStrings.roadTest,
  'technicianConsentProcessingBody': FigmaTestStrings.roadTestBody,
  'technicianDataStorage': FigmaTestStrings.dataStorage,
  'technicianUnavailable': FigmaTestStrings.dataStorageBody,
  'technicianConsentDecision': FigmaTestStrings.digitalSignature,
  'technicianConsentHint': FigmaTestStrings.signHint,
  'technicianNoSignature': FigmaTestStrings.signAbove,
  'technicianConsentSave': FigmaTestStrings.saveConsent,
  'technicianPreInspectionSetup': FigmaTestStrings.setupKicker,
  'technicianItemsCount': FigmaTestStrings.verifiedPill,
  'technicianRequiredEquipment': FigmaTestStrings.requiredEquipment,
  'technicianEquipmentIntro': FigmaTestStrings.equipmentIntro,
  'technicianEquipmentStandards': FigmaTestStrings.stationStandards,
  'technicianEquipmentStandardsBody': FigmaTestStrings.stationStandardsBody,
  'technicianInspectionHub': FigmaTestStrings.hubTitle,
  'technicianNoIssueCount': '{count} ${FigmaTestStrings.passedPill}',
  'technicianAttentionCount': '{count} ${FigmaTestStrings.actionItems}',
  'technicianInspectionModules': FigmaTestStrings.modulesTitle,
  'technicianModuleNotStarted': FigmaTestStrings.queued,
  'technicianModuleInProgress': 'Active Bay',
  'technicianCategoriesCount': ' Categories',
  'technicianContinueChecklist': 'Continue Interior Checklist',
  'technicianChecksCount': '{done}/{total} Done',
  'defectFound': 'Front Left Door Dent',
};

/// Figma copy layered over the backend English bundle.
UiStrings figmaStrings() => UiStrings.fromRemoteEnglish(figmaMessageOverrides);
