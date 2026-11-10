import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:l10n/l10n.dart';
import 'package:l10n/l10n/gen/app_localizations_en.dart';

/// Test-only Figma-text localization override.
///
/// The F2-A fidelity fixtures compare production widgets against the Figma
/// mock pixel-for-pixel. Figma sample wording (e.g. `TechInspect`,
/// `David Vance`, `Renault Megane 3`, `Bay 04`) must therefore render in
/// tests but must never ship in `lib/`.
///
/// Figma wording that is *data* (names, VINs, plates) travels through the
/// normal product model fields ([figmaJobs], [figmaJob], [figmaChecklist]).
/// Figma wording that is *chrome copy* is supplied here: [FigmaTestStrings]
/// documents every sample string, and [FigmaTestLocalizations] serves it
/// through the regular [AppLocalizations] API so production widgets render
/// Figma text without any `figmaText` switch in `lib/`.
///
/// Usage: pump the screen with [figmaLocalizationsDelegates] instead of
/// [AppLocalizations.localizationsDelegates] (see `f2a_views.dart`).
/// English only; product Arabic coverage is exercised with the real delegate.
abstract final class FigmaTestStrings {
  // Login (auth/SignInView reads these from AppLocalizations).
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
  static const consentIntro = 'Review compliance permissions and provide\ncustomer digital sign-off.';
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

/// English [AppLocalizations] that returns Figma sample wording for the keys
/// listed in [FigmaTestStrings]. Every other key falls through to the real
/// English copy.
class FigmaTestLocalizations extends AppLocalizationsEn {
  FigmaTestLocalizations() : super('en');

  @override
  String get appTitle => FigmaTestStrings.brand;

  @override
  String get technicianSignInTagline => FigmaTestStrings.tagline;

  @override
  String get technicianPasswordHelp => FigmaTestStrings.forgotPassword;

  @override
  String get signInButton => FigmaTestStrings.signIn;

  @override
  String get technicianContactAdmin => FigmaTestStrings.requestId;

  @override
  String get technicianNeedTechnicianAccess => FigmaTestStrings.needAccess;

  @override
  String get technicianSecurityLine => FigmaTestStrings.isoSecurity;

  // The Figma mock's language switch shows "Ø¹Ø±Ø¨ÙŠ"; product copy uses the
  // localized "Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©" (l10n.languageArabic).
  @override
  String get languageArabic => 'Ø¹Ø±Ø¨ÙŠ';

  @override
  String technicianShiftToday(int count) => FigmaTestStrings.shiftAndBay;

  @override
  String get technicianOnlineSync => FigmaTestStrings.onlineSync;

  @override
  String get technicianJobIntake => 'INTAKE PHASE';

  @override
  String get statusAssigned => 'Ready for Check';

  @override
  String get technicianJobsTitle => FigmaTestStrings.intakeTab;

  @override
  String get statusFinalized => FigmaTestStrings.fleetTab;

  @override
  String technicianJobsInQueue(int count) => FigmaTestStrings.inQueue(count);

  @override
  String get walkInJob => FigmaTestStrings.scanVin;

  @override
  String get technicianInspectionQueue => 'Inspection Queue';

  @override
  String get technicianQueueEmpty => FigmaTestStrings.shiftActive;

  @override
  String technicianJobsCount(int count) => FigmaTestStrings.bayPill;

  @override
  String get technicianAllCaughtUp => FigmaTestStrings.caughtUp;

  @override
  String get technicianNoJobsBody => FigmaTestStrings.noJobsBody;

  @override
  String get technicianRefreshQueue => FigmaTestStrings.refreshQueue;

  @override
  String get technicianCoverageOnly => FigmaTestStrings.passRate;

  @override
  String get technicianWelcomeBack => 'Welcome back,';

  @override
  String get technicianAssignedToday => 'Assigned today';

  @override
  String get technicianVehicleInfo => FigmaTestStrings.vehicleInfo;

  @override
  String get technicianPhone => 'Phone Number';

  @override
  String get technicianCustomerChip => FigmaTestStrings.primaryOwner;

  @override
  String get technicianJobDetailsReady => FigmaTestStrings.jobReady;

  @override
  String get startInspection => FigmaTestStrings.startInspection;

  @override
  String get technicianConsentStep => FigmaTestStrings.consentSteps;

  @override
  String get consent => FigmaTestStrings.authorizations;

  @override
  String get technicianConsentIntro => FigmaTestStrings.consentIntro;

  @override
  String get consentPublicLink => FigmaTestStrings.allowPdf;

  @override
  String get technicianConsentPublicLinkBody => FigmaTestStrings.allowPdfBody;

  @override
  String get consentProcessing => FigmaTestStrings.roadTest;

  @override
  String get technicianConsentProcessingBody => FigmaTestStrings.roadTestBody;

  @override
  String get technicianDataStorage => FigmaTestStrings.dataStorage;

  @override
  String get technicianUnavailable => FigmaTestStrings.dataStorageBody;

  @override
  String get technicianConsentDecision => FigmaTestStrings.digitalSignature;

  @override
  String get technicianConsentHint => FigmaTestStrings.signHint;

  @override
  String get technicianNoSignature => FigmaTestStrings.signAbove;

  @override
  String get technicianConsentSave => FigmaTestStrings.saveConsent;

  @override
  String get technicianPreInspectionSetup => FigmaTestStrings.setupKicker;

  @override
  String technicianItemsCount(int count) => FigmaTestStrings.verifiedPill;

  @override
  String get technicianRequiredEquipment => FigmaTestStrings.requiredEquipment;

  @override
  String get technicianEquipmentIntro => FigmaTestStrings.equipmentIntro;

  @override
  String get technicianEquipmentStandards => FigmaTestStrings.stationStandards;

  @override
  String get technicianEquipmentStandardsBody =>
      FigmaTestStrings.stationStandardsBody;

  @override
  String get technicianInspectionHub => FigmaTestStrings.hubTitle;

  @override
  String technicianNoIssueCount(int count) =>
      '$count ${FigmaTestStrings.passedPill}';

  @override
  String technicianAttentionCount(int count) =>
      '$count ${FigmaTestStrings.actionItems}';

  @override
  String get technicianInspectionModules => FigmaTestStrings.modulesTitle;

  @override
  String get technicianModuleNotStarted => FigmaTestStrings.queued;

  @override
  String get technicianModuleInProgress => 'Active Bay';

  @override
  String technicianCategoriesCount(int count) => ' Categories';

  @override
  String get technicianContinueChecklist => 'Continue Interior Checklist';

  @override
  String technicianChecksCount(int done, int total) =>
      FigmaTestStrings.checksDone(done, total);

  @override
  String get defectFound => 'Front Left Door Dent';
}

/// [LocalizationsDelegate] serving [FigmaTestLocalizations] for English.
/// Replaces [AppLocalizations.delegate] in fidelity fixtures; global
/// Material/Cupertino/Widgets delegates must still be provided by the host.
class FigmaTestLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const FigmaTestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      FigmaTestLocalizations();

  @override
  bool shouldReload(FigmaTestLocalizationsDelegate old) => false;
}

/// Drop-in replacement for [AppLocalizations.localizationsDelegates] that
/// renders Figma sample copy instead of product copy. English only.
const figmaLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  FigmaTestLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
