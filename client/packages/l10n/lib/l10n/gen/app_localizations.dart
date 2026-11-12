import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TrueReport'**
  String get appTitle;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your workshop account.'**
  String get signInSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @twoFactorLabel.
  ///
  /// In en, this message translates to:
  /// **'Authentication code'**
  String get twoFactorLabel;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @roleTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get roleTechnician;

  /// No description provided for @roleWorkshopAdmin.
  ///
  /// In en, this message translates to:
  /// **'Workshop Admin'**
  String get roleWorkshopAdmin;

  /// No description provided for @rolePlatformAdmin.
  ///
  /// In en, this message translates to:
  /// **'Platform Admin'**
  String get rolePlatformAdmin;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Foundation home'**
  String get homeTitle;

  /// No description provided for @homeBody.
  ///
  /// In en, this message translates to:
  /// **'Phase 2 foundation only. Feature screens are not built yet.'**
  String get homeBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get invalidCredentials;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection.'**
  String get networkError;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get genericError;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline. Work will be saved on this phone.'**
  String get offlineBanner;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @platformAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Admin'**
  String get platformAdminTitle;

  /// No description provided for @hierarchyTab.
  ///
  /// In en, this message translates to:
  /// **'Hierarchy'**
  String get hierarchyTab;

  /// No description provided for @masterContentTab.
  ///
  /// In en, this message translates to:
  /// **'Master content'**
  String get masterContentTab;

  /// No description provided for @auditTab.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get auditTab;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending invitation'**
  String get pending;

  /// No description provided for @workshops.
  ///
  /// In en, this message translates to:
  /// **'Workshops'**
  String get workshops;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Workshop Admins'**
  String get admins;

  /// No description provided for @technicians.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get technicians;

  /// No description provided for @pendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get pendingInvitations;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get members;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @reactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivate;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @retire.
  ///
  /// In en, this message translates to:
  /// **'Retire'**
  String get retire;

  /// No description provided for @versions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get versions;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Inspection items'**
  String get items;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get newItem;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @temporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get temporaryPassword;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @workshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get workshop;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @auditHistory.
  ///
  /// In en, this message translates to:
  /// **'Audit history'**
  String get auditHistory;

  /// No description provided for @occurredAt.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get occurredAt;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @entity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get entity;

  /// No description provided for @categoryNameEn.
  ///
  /// In en, this message translates to:
  /// **'Category name (English)'**
  String get categoryNameEn;

  /// No description provided for @categoryNameAr.
  ///
  /// In en, this message translates to:
  /// **'Category name (Arabic)'**
  String get categoryNameAr;

  /// No description provided for @slug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get slug;

  /// No description provided for @labelEn.
  ///
  /// In en, this message translates to:
  /// **'Label (English)'**
  String get labelEn;

  /// No description provided for @labelAr.
  ///
  /// In en, this message translates to:
  /// **'Label (Arabic)'**
  String get labelAr;

  /// No description provided for @instructionEn.
  ///
  /// In en, this message translates to:
  /// **'English instruction'**
  String get instructionEn;

  /// No description provided for @instructionAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic instruction'**
  String get instructionAr;

  /// No description provided for @stableCode.
  ///
  /// In en, this message translates to:
  /// **'Stable code'**
  String get stableCode;

  /// No description provided for @resultOptions.
  ///
  /// In en, this message translates to:
  /// **'Result options'**
  String get resultOptions;

  /// No description provided for @severityPolicy.
  ///
  /// In en, this message translates to:
  /// **'Severity policy'**
  String get severityPolicy;

  /// No description provided for @applicability.
  ///
  /// In en, this message translates to:
  /// **'Applicability'**
  String get applicability;

  /// No description provided for @noteRequirement.
  ///
  /// In en, this message translates to:
  /// **'Note requirement'**
  String get noteRequirement;

  /// No description provided for @evidenceRequirement.
  ///
  /// In en, this message translates to:
  /// **'Evidence requirement'**
  String get evidenceRequirement;

  /// No description provided for @minPhotos.
  ///
  /// In en, this message translates to:
  /// **'Min photos'**
  String get minPhotos;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @reasons.
  ///
  /// In en, this message translates to:
  /// **'Reasons'**
  String get reasons;

  /// No description provided for @guideImage.
  ///
  /// In en, this message translates to:
  /// **'Guide image'**
  String get guideImage;

  /// No description provided for @sampleData.
  ///
  /// In en, this message translates to:
  /// **'Placeholder sample data'**
  String get sampleData;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @retired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get retired;

  /// No description provided for @createDraft.
  ///
  /// In en, this message translates to:
  /// **'Create draft'**
  String get createDraft;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @uploadGuideImage.
  ///
  /// In en, this message translates to:
  /// **'Upload guide image'**
  String get uploadGuideImage;

  /// No description provided for @guideImageAltEn.
  ///
  /// In en, this message translates to:
  /// **'Guide image alt text (English)'**
  String get guideImageAltEn;

  /// No description provided for @guideImageAltAr.
  ///
  /// In en, this message translates to:
  /// **'Guide image alt text (Arabic)'**
  String get guideImageAltAr;

  /// No description provided for @licenceNote.
  ///
  /// In en, this message translates to:
  /// **'Licence note'**
  String get licenceNote;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @invitationToken.
  ///
  /// In en, this message translates to:
  /// **'Invitation token'**
  String get invitationToken;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemCount;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get accountCreated;

  /// No description provided for @invitationCreated.
  ///
  /// In en, this message translates to:
  /// **'Invitation created'**
  String get invitationCreated;

  /// No description provided for @contentSaved.
  ///
  /// In en, this message translates to:
  /// **'Content saved'**
  String get contentSaved;

  /// No description provided for @versionPublished.
  ///
  /// In en, this message translates to:
  /// **'Version published'**
  String get versionPublished;

  /// No description provided for @itemRetired.
  ///
  /// In en, this message translates to:
  /// **'Item retired'**
  String get itemRetired;

  /// No description provided for @retireItem.
  ///
  /// In en, this message translates to:
  /// **'Retire item'**
  String get retireItem;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get actionFailed;

  /// No description provided for @workshopAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Workshop Admin'**
  String get workshopAdminTitle;

  /// No description provided for @jobsTab.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobsTab;

  /// No description provided for @staffTab.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffTab;

  /// No description provided for @templatesTab.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templatesTab;

  /// No description provided for @dashboardTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardTab;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Platform overview and recent activity'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardStatActive.
  ///
  /// In en, this message translates to:
  /// **'Active jobs'**
  String get dashboardStatActive;

  /// No description provided for @dashboardStatNewScheduled.
  ///
  /// In en, this message translates to:
  /// **'New & scheduled'**
  String get dashboardStatNewScheduled;

  /// No description provided for @dashboardStatFinalizedToday.
  ///
  /// In en, this message translates to:
  /// **'Finalized today'**
  String get dashboardStatFinalizedToday;

  /// No description provided for @dashboardRecentJobs.
  ///
  /// In en, this message translates to:
  /// **'Recent jobs'**
  String get dashboardRecentJobs;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation queue'**
  String get queueTitle;

  /// No description provided for @scheduleJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule new job'**
  String get scheduleJobTitle;

  /// No description provided for @scheduleJobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the job in this workshop — assign a technician afterwards'**
  String get scheduleJobSubtitle;

  /// No description provided for @assignTechnicianTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign technician'**
  String get assignTechnicianTitle;

  /// No description provided for @assignTechnicianSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select an available technician'**
  String get assignTechnicianSubtitle;

  /// No description provided for @assignReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get assignReasonOptional;

  /// No description provided for @workshopStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'Workshop Staff'**
  String get workshopStaffTitle;

  /// No description provided for @staffFilterTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get staffFilterTechnicians;

  /// No description provided for @staffFilterAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get staffFilterAdmins;

  /// No description provided for @staffResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get staffResetPassword;

  /// No description provided for @createTechnicianTitle.
  ///
  /// In en, this message translates to:
  /// **'Create technician'**
  String get createTechnicianTitle;

  /// No description provided for @createTechnicianSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the name, email and initial password. The technician signs in with these credentials.'**
  String get createTechnicianSubtitle;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailAlreadyInUse;

  /// No description provided for @templateListTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection templates'**
  String get templateListTitle;

  /// No description provided for @templateTotalCheckpoints.
  ///
  /// In en, this message translates to:
  /// **'Total checkpoints'**
  String get templateTotalCheckpoints;

  /// No description provided for @templatesUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String templatesUpdatedOn(String date);

  /// No description provided for @templateViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get templateViewGrid;

  /// No description provided for @templateViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get templateViewList;

  /// No description provided for @builderMasterItems.
  ///
  /// In en, this message translates to:
  /// **'Master items'**
  String get builderMasterItems;

  /// No description provided for @builderSequenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Template sequence'**
  String get builderSequenceTitle;

  /// No description provided for @builderDropHint.
  ///
  /// In en, this message translates to:
  /// **'Drop checkpoint here'**
  String get builderDropHint;

  /// No description provided for @newJob.
  ///
  /// In en, this message translates to:
  /// **'New job'**
  String get newJob;

  /// No description provided for @jobSearch.
  ///
  /// In en, this message translates to:
  /// **'Search jobs'**
  String get jobSearch;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusReadyToFinalize.
  ///
  /// In en, this message translates to:
  /// **'Ready to finalize'**
  String get statusReadyToFinalize;

  /// No description provided for @statusFinalized.
  ///
  /// In en, this message translates to:
  /// **'Finalized'**
  String get statusFinalized;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// No description provided for @cancelJob.
  ///
  /// In en, this message translates to:
  /// **'Cancel job'**
  String get cancelJob;

  /// No description provided for @jobCreated.
  ///
  /// In en, this message translates to:
  /// **'Job created'**
  String get jobCreated;

  /// No description provided for @jobAssigned.
  ///
  /// In en, this message translates to:
  /// **'Job assigned'**
  String get jobAssigned;

  /// No description provided for @jobCancelled.
  ///
  /// In en, this message translates to:
  /// **'Job cancelled'**
  String get jobCancelled;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get customerName;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer phone'**
  String get customerPhone;

  /// No description provided for @customerEmail.
  ///
  /// In en, this message translates to:
  /// **'Customer email'**
  String get customerEmail;

  /// No description provided for @vehicleMake.
  ///
  /// In en, this message translates to:
  /// **'Vehicle make'**
  String get vehicleMake;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle model'**
  String get vehicleModel;

  /// No description provided for @vehicleYear.
  ///
  /// In en, this message translates to:
  /// **'Vehicle year'**
  String get vehicleYear;

  /// No description provided for @vehicleVin.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get vehicleVin;

  /// No description provided for @vehiclePlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get vehiclePlate;

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Inspection scope'**
  String get scope;

  /// No description provided for @scheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled at'**
  String get scheduledAt;

  /// No description provided for @template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get template;

  /// No description provided for @selectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select a template'**
  String get selectTemplate;

  /// No description provided for @staffReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Staff accounts'**
  String get staffReadOnly;

  /// No description provided for @staffReadOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Platform Admin creates workshop accounts. Workshop Admins can review staff and assign jobs.'**
  String get staffReadOnlyBody;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Global templates'**
  String get templates;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get newTemplate;

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateName;

  /// No description provided for @templateDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get templateDescription;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service type'**
  String get serviceType;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get vehicleType;

  /// No description provided for @addItems.
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get addItems;

  /// No description provided for @selectedItems.
  ///
  /// In en, this message translates to:
  /// **'Selected items'**
  String get selectedItems;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @previewEn.
  ///
  /// In en, this message translates to:
  /// **'English preview'**
  String get previewEn;

  /// No description provided for @previewAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic preview'**
  String get previewAr;

  /// No description provided for @publishTemplate.
  ///
  /// In en, this message translates to:
  /// **'Publish template'**
  String get publishTemplate;

  /// No description provided for @versionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get versionHistory;

  /// No description provided for @lockedByPlatform.
  ///
  /// In en, this message translates to:
  /// **'Locked by platform'**
  String get lockedByPlatform;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items selected'**
  String get noItems;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @templatePublished.
  ///
  /// In en, this message translates to:
  /// **'Template published'**
  String get templatePublished;

  /// No description provided for @jobAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get jobAssignedTo;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @noTechnicians.
  ///
  /// In en, this message translates to:
  /// **'No active technicians'**
  String get noTechnicians;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search approved items'**
  String get searchItems;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @masterVersion.
  ///
  /// In en, this message translates to:
  /// **'Master version'**
  String get masterVersion;

  /// No description provided for @readOnlyVersion.
  ///
  /// In en, this message translates to:
  /// **'Read-only version'**
  String get readOnlyVersion;

  /// No description provided for @itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'items selected'**
  String get itemsSelected;

  /// No description provided for @templateDetails.
  ///
  /// In en, this message translates to:
  /// **'Template details'**
  String get templateDetails;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get jobDetails;

  /// No description provided for @assignedJobs.
  ///
  /// In en, this message translates to:
  /// **'Assigned jobs'**
  String get assignedJobs;

  /// No description provided for @noAssignedJobs.
  ///
  /// In en, this message translates to:
  /// **'No jobs assigned. Ask your Workshop Admin, or create a walk-in job.'**
  String get noAssignedJobs;

  /// No description provided for @walkInJob.
  ///
  /// In en, this message translates to:
  /// **'Walk-in job'**
  String get walkInJob;

  /// No description provided for @startInspection.
  ///
  /// In en, this message translates to:
  /// **'Start inspection'**
  String get startInspection;

  /// No description provided for @resumeInspection.
  ///
  /// In en, this message translates to:
  /// **'Resume inspection'**
  String get resumeInspection;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'Customer information'**
  String get customerInformation;

  /// No description provided for @vehicleIdentification.
  ///
  /// In en, this message translates to:
  /// **'Vehicle identification'**
  String get vehicleIdentification;

  /// No description provided for @consent.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get consent;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @reviewAndFinalize.
  ///
  /// In en, this message translates to:
  /// **'Review and finalize'**
  String get reviewAndFinalize;

  /// No description provided for @approveAndGenerateReport.
  ///
  /// In en, this message translates to:
  /// **'Finalize inspection'**
  String get approveAndGenerateReport;

  /// No description provided for @finalizedReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Finalized — read only'**
  String get finalizedReadOnly;

  /// No description provided for @evidenceNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Evidence capture is not available in this build.'**
  String get evidenceNotAvailable;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked'**
  String get notChecked;

  /// No description provided for @couldNotVerify.
  ///
  /// In en, this message translates to:
  /// **'Could not verify'**
  String get couldNotVerify;

  /// No description provided for @noIssueObserved.
  ///
  /// In en, this message translates to:
  /// **'No issue observed'**
  String get noIssueObserved;

  /// No description provided for @defectFound.
  ///
  /// In en, this message translates to:
  /// **'Defect found'**
  String get defectFound;

  /// No description provided for @attentionRecommended.
  ///
  /// In en, this message translates to:
  /// **'Attention recommended'**
  String get attentionRecommended;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get notApplicable;

  /// No description provided for @minor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get minor;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @major.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get major;

  /// No description provided for @safetyCritical.
  ///
  /// In en, this message translates to:
  /// **'Safety critical'**
  String get safetyCritical;

  /// No description provided for @saveAnswer.
  ///
  /// In en, this message translates to:
  /// **'Save answer'**
  String get saveAnswer;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @completedItems.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completedItems;

  /// No description provided for @missingItems.
  ///
  /// In en, this message translates to:
  /// **'Missing items'**
  String get missingItems;

  /// No description provided for @itemSaved.
  ///
  /// In en, this message translates to:
  /// **'Answer saved'**
  String get itemSaved;

  /// No description provided for @inspectionStarted.
  ///
  /// In en, this message translates to:
  /// **'Inspection started'**
  String get inspectionStarted;

  /// No description provided for @readyToFinalize.
  ///
  /// In en, this message translates to:
  /// **'Ready to finalize'**
  String get readyToFinalize;

  /// No description provided for @finalizeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Finalize this inspection?'**
  String get finalizeConfirm;

  /// No description provided for @finalizeIrreversible.
  ///
  /// In en, this message translates to:
  /// **'Finalized findings cannot be edited by anyone.'**
  String get finalizeIrreversible;

  /// No description provided for @finalizedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Inspection finalized'**
  String get finalizedSuccessfully;

  /// No description provided for @walkInCreated.
  ///
  /// In en, this message translates to:
  /// **'Walk-in job created'**
  String get walkInCreated;

  /// No description provided for @customerSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer details saved'**
  String get customerSaved;

  /// No description provided for @vehicleSaved.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details saved'**
  String get vehicleSaved;

  /// No description provided for @consentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Consent recorded'**
  String get consentRecorded;

  /// No description provided for @assessmentRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a result first'**
  String get assessmentRequired;

  /// No description provided for @keyboardHelp.
  ///
  /// In en, this message translates to:
  /// **'Use your device keyboard settings to switch Arabic, Russian or Chinese input.'**
  String get keyboardHelp;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// No description provided for @evidencePending.
  ///
  /// In en, this message translates to:
  /// **'Evidence pending (not available in this build)'**
  String get evidencePending;

  /// No description provided for @consentProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing consent'**
  String get consentProcessing;

  /// No description provided for @consentPublicLink.
  ///
  /// In en, this message translates to:
  /// **'Public-link consent'**
  String get consentPublicLink;

  /// No description provided for @consentGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get consentGranted;

  /// No description provided for @consentRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get consentRefused;

  /// No description provided for @consentWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get consentWithdrawn;

  /// No description provided for @consentRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get consentRequired;

  /// No description provided for @finalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get finalize;

  /// No description provided for @markReady.
  ///
  /// In en, this message translates to:
  /// **'Mark ready'**
  String get markReady;

  /// No description provided for @inspectionScope.
  ///
  /// In en, this message translates to:
  /// **'Inspection scope'**
  String get inspectionScope;

  /// No description provided for @odometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get odometer;

  /// No description provided for @odometerUnit.
  ///
  /// In en, this message translates to:
  /// **'Odometer unit'**
  String get odometerUnit;

  /// No description provided for @walkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walkIn;

  /// No description provided for @technicianHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technicianHomeTitle;

  /// No description provided for @syncQueue.
  ///
  /// In en, this message translates to:
  /// **'Sync queue'**
  String get syncQueue;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @savedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get savedOnPhone;

  /// No description provided for @receivedByServer.
  ///
  /// In en, this message translates to:
  /// **'Received by server'**
  String get receivedByServer;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @photoSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get photoSourceCamera;

  /// No description provided for @photoSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get photoSourceGallery;

  /// No description provided for @photoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved on this phone'**
  String get photoSaved;

  /// No description provided for @photoRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo.'**
  String get photoRequired;

  /// No description provided for @noPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting to sync.'**
  String get noPendingSync;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Changes synced.'**
  String get syncComplete;

  /// No description provided for @guideImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Guide image is unavailable offline.'**
  String get guideImageUnavailable;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get attachments;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportStatus.
  ///
  /// In en, this message translates to:
  /// **'Report status'**
  String get reportStatus;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get generating;

  /// No description provided for @reportReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get reportReady;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get reportFailed;

  /// No description provided for @retryReport.
  ///
  /// In en, this message translates to:
  /// **'Retry report'**
  String get retryReport;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @createLink.
  ///
  /// In en, this message translates to:
  /// **'Create public link'**
  String get createLink;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @deactivateLink.
  ///
  /// In en, this message translates to:
  /// **'Deactivate link'**
  String get deactivateLink;

  /// No description provided for @linkActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get linkActive;

  /// No description provided for @linkRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get linkRevoked;

  /// No description provided for @linkPendingConsent.
  ///
  /// In en, this message translates to:
  /// **'Pending consent'**
  String get linkPendingConsent;

  /// No description provided for @publicLink.
  ///
  /// In en, this message translates to:
  /// **'Public link'**
  String get publicLink;

  /// No description provided for @pdfDownload.
  ///
  /// In en, this message translates to:
  /// **'PDF download'**
  String get pdfDownload;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @consentNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Public-link consent is not recorded.'**
  String get consentNotGranted;

  /// No description provided for @reportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Report is not ready.'**
  String get reportUnavailable;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @deactivateReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for deactivation'**
  String get deactivateReason;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @reportVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Report version'**
  String get reportVersionLabel;

  /// No description provided for @snapshotHash.
  ///
  /// In en, this message translates to:
  /// **'Snapshot hash'**
  String get snapshotHash;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get viewReport;

  /// No description provided for @pdfBytesSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved'**
  String get pdfBytesSaved;

  /// No description provided for @finalized.
  ///
  /// In en, this message translates to:
  /// **'Finalized'**
  String get finalized;

  /// No description provided for @coverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get coverage;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @keyFindings.
  ///
  /// In en, this message translates to:
  /// **'Key findings'**
  String get keyFindings;

  /// No description provided for @findings.
  ///
  /// In en, this message translates to:
  /// **'Findings'**
  String get findings;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @deliveryHistory.
  ///
  /// In en, this message translates to:
  /// **'Delivery history'**
  String get deliveryHistory;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// No description provided for @sendReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReportTitle;

  /// No description provided for @deliveryChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get deliveryChannel;

  /// No description provided for @deliveryLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get deliveryLanguage;

  /// No description provided for @deliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivery status'**
  String get deliveryStatus;

  /// No description provided for @deliveryRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get deliveryRecipient;

  /// No description provided for @deliveryAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get deliveryAttempts;

  /// No description provided for @deliveryNextAttempt.
  ///
  /// In en, this message translates to:
  /// **'Next attempt'**
  String get deliveryNextAttempt;

  /// No description provided for @deliveryError.
  ///
  /// In en, this message translates to:
  /// **'Last error'**
  String get deliveryError;

  /// No description provided for @retryDelivery.
  ///
  /// In en, this message translates to:
  /// **'Retry delivery'**
  String get retryDelivery;

  /// No description provided for @deliveryQueued.
  ///
  /// In en, this message translates to:
  /// **'Delivery queued'**
  String get deliveryQueued;

  /// No description provided for @deliverySent.
  ///
  /// In en, this message translates to:
  /// **'Delivery sent'**
  String get deliverySent;

  /// No description provided for @noDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No delivery attempts yet.'**
  String get noDeliveries;

  /// No description provided for @channelWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get channelWhatsapp;

  /// No description provided for @channelSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get channelSms;

  /// No description provided for @channelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get channelEmail;

  /// No description provided for @deliveryConsentHint.
  ///
  /// In en, this message translates to:
  /// **'Channel consent must be recorded before sending.'**
  String get deliveryConsentHint;

  /// No description provided for @deliveryPdfAttached.
  ///
  /// In en, this message translates to:
  /// **'PDF attached'**
  String get deliveryPdfAttached;

  /// No description provided for @deliveryLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get deliveryLink;

  /// No description provided for @technicianWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get technicianWelcomeBack;

  /// No description provided for @technicianJobsInQueue.
  ///
  /// In en, this message translates to:
  /// **'{count} in queue'**
  String technicianJobsInQueue(int count);

  /// No description provided for @technicianAssignedToday.
  ///
  /// In en, this message translates to:
  /// **'Assigned today'**
  String get technicianAssignedToday;

  /// No description provided for @technicianPendingCheck.
  ///
  /// In en, this message translates to:
  /// **'Pending check'**
  String get technicianPendingCheck;

  /// No description provided for @technicianJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get technicianJobsTitle;

  /// No description provided for @technicianSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get technicianSyncTitle;

  /// No description provided for @technicianProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get technicianProfileTitle;

  /// No description provided for @technicianProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get technicianProfileSubtitle;

  /// No description provided for @technicianLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get technicianLanguage;

  /// No description provided for @technicianAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up'**
  String get technicianAllCaughtUp;

  /// No description provided for @technicianNoJobsBody.
  ///
  /// In en, this message translates to:
  /// **'No pending inspections are assigned to you.'**
  String get technicianNoJobsBody;

  /// No description provided for @technicianRefreshQueue.
  ///
  /// In en, this message translates to:
  /// **'Refresh queue'**
  String get technicianRefreshQueue;

  /// No description provided for @technicianQueueRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Queue refreshed'**
  String get technicianQueueRefreshed;

  /// No description provided for @technicianJobIntake.
  ///
  /// In en, this message translates to:
  /// **'Job intake'**
  String get technicianJobIntake;

  /// No description provided for @technicianVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle info'**
  String get technicianVehicleInfo;

  /// No description provided for @technicianCustomerInfo.
  ///
  /// In en, this message translates to:
  /// **'Customer info'**
  String get technicianCustomerInfo;

  /// No description provided for @technicianMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get technicianMake;

  /// No description provided for @technicianModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get technicianModel;

  /// No description provided for @technicianYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get technicianYear;

  /// No description provided for @technicianOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get technicianOdometer;

  /// No description provided for @technicianVin.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get technicianVin;

  /// No description provided for @technicianPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get technicianPlate;

  /// No description provided for @technicianPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get technicianPhone;

  /// No description provided for @technicianEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get technicianEmail;

  /// No description provided for @technicianTemplate.
  ///
  /// In en, this message translates to:
  /// **'Inspection template'**
  String get technicianTemplate;

  /// No description provided for @technicianScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get technicianScope;

  /// No description provided for @technicianNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get technicianNotProvided;

  /// No description provided for @technicianCopyVin.
  ///
  /// In en, this message translates to:
  /// **'Copy VIN'**
  String get technicianCopyVin;

  /// No description provided for @technicianVinCopied.
  ///
  /// In en, this message translates to:
  /// **'VIN copied'**
  String get technicianVinCopied;

  /// No description provided for @technicianConsentIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose each consent separately. Nothing is recorded until you save.'**
  String get technicianConsentIntro;

  /// No description provided for @technicianConsentProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Record the customer answer for processing inspection data.'**
  String get technicianConsentProcessingBody;

  /// No description provided for @technicianConsentPublicLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Record the customer answer for sharing the public report link.'**
  String get technicianConsentPublicLinkBody;

  /// No description provided for @technicianConsentSave.
  ///
  /// In en, this message translates to:
  /// **'Save consent'**
  String get technicianConsentSave;

  /// No description provided for @technicianConsentNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded yet'**
  String get technicianConsentNotRecorded;

  /// No description provided for @technicianChecksDone.
  ///
  /// In en, this message translates to:
  /// **'checks done'**
  String get technicianChecksDone;

  /// No description provided for @technicianInspectionHub.
  ///
  /// In en, this message translates to:
  /// **'Inspection hub'**
  String get technicianInspectionHub;

  /// No description provided for @technicianInspectionInProgress.
  ///
  /// In en, this message translates to:
  /// **'Inspection in progress'**
  String get technicianInspectionInProgress;

  /// No description provided for @technicianInspectionModules.
  ///
  /// In en, this message translates to:
  /// **'Inspection modules'**
  String get technicianInspectionModules;

  /// No description provided for @technicianCategoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String technicianCategoriesCount(int count);

  /// No description provided for @technicianChecksCount.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} checks'**
  String technicianChecksCount(int done, int total);

  /// No description provided for @technicianModuleDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get technicianModuleDone;

  /// No description provided for @technicianModuleInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get technicianModuleInProgress;

  /// No description provided for @technicianModuleNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get technicianModuleNotStarted;

  /// No description provided for @technicianNoIssueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} no issue observed'**
  String technicianNoIssueCount(int count);

  /// No description provided for @technicianAttentionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attention'**
  String technicianAttentionCount(int count);

  /// No description provided for @technicianDefectsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} defects'**
  String technicianDefectsCount(int count);

  /// No description provided for @technicianContinueChecklist.
  ///
  /// In en, this message translates to:
  /// **'Continue checklist'**
  String get technicianContinueChecklist;

  /// No description provided for @technicianCoverageSemantics.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} checks done'**
  String technicianCoverageSemantics(int done, int total);

  /// No description provided for @technicianVehicleSilhouette.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type silhouette'**
  String get technicianVehicleSilhouette;

  /// No description provided for @technicianUnknownVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get technicianUnknownVehicle;

  /// No description provided for @technicianStartHint.
  ///
  /// In en, this message translates to:
  /// **'Start the inspection when the vehicle and customer details are confirmed.'**
  String get technicianStartHint;

  /// No description provided for @technicianSignInTagline.
  ///
  /// In en, this message translates to:
  /// **'Vehicle inspection reports for partner workshops.'**
  String get technicianSignInTagline;

  /// No description provided for @technicianAccountNote.
  ///
  /// In en, this message translates to:
  /// **'Your workshop account is created by a Platform Admin.'**
  String get technicianAccountNote;

  /// No description provided for @technicianLanguagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get technicianLanguagePrompt;

  /// No description provided for @technicianSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get technicianSignedInAs;

  /// No description provided for @technicianPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Changes saved on this phone'**
  String get technicianPendingSync;

  /// No description provided for @technicianAllSynced.
  ///
  /// In en, this message translates to:
  /// **'No changes waiting to sync'**
  String get technicianAllSynced;

  /// No description provided for @technicianEquipmentIdsOnly.
  ///
  /// In en, this message translates to:
  /// **'Equipment names are not available from the server in this build.'**
  String get technicianEquipmentIdsOnly;

  /// No description provided for @technicianOfTotal.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String technicianOfTotal(int total);

  /// No description provided for @technicianInspectionQueue.
  ///
  /// In en, this message translates to:
  /// **'Inspection Queue'**
  String get technicianInspectionQueue;

  /// No description provided for @technicianLiveSync.
  ///
  /// In en, this message translates to:
  /// **'LIVE\nSYNC'**
  String get technicianLiveSync;

  /// No description provided for @technicianOnlineSync.
  ///
  /// In en, this message translates to:
  /// **'ONLINE\nSYNC'**
  String get technicianOnlineSync;

  /// No description provided for @technicianOfflineSync.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE\nSYNC'**
  String get technicianOfflineSync;

  /// No description provided for @technicianShiftToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY • {count} JOBS'**
  String technicianShiftToday(int count);

  /// No description provided for @technicianShiftActive.
  ///
  /// In en, this message translates to:
  /// **'SHIFT ACTIVE'**
  String get technicianShiftActive;

  /// No description provided for @technicianQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'QUEUE EMPTY'**
  String get technicianQueueEmpty;

  /// No description provided for @technicianJobsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} JOBS'**
  String technicianJobsCount(int count);

  /// No description provided for @technicianTodaySummary.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S SUMMARY'**
  String get technicianTodaySummary;

  /// No description provided for @technicianCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'{count} Completed'**
  String technicianCompletedToday(int count);

  /// No description provided for @technicianQueueCurrent.
  ///
  /// In en, this message translates to:
  /// **'Queue is current'**
  String get technicianQueueCurrent;

  /// No description provided for @technicianCoverageOnly.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get technicianCoverageOnly;

  /// No description provided for @technicianPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Password help'**
  String get technicianPasswordHelp;

  /// No description provided for @technicianNeedTechnicianAccess.
  ///
  /// In en, this message translates to:
  /// **'Need technician login?'**
  String get technicianNeedTechnicianAccess;

  /// No description provided for @technicianContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get technicianContactAdmin;

  /// No description provided for @technicianSecureDelivery.
  ///
  /// In en, this message translates to:
  /// **'Secure report delivery'**
  String get technicianSecureDelivery;

  /// No description provided for @technicianRequiredEquipment.
  ///
  /// In en, this message translates to:
  /// **'Required Equipment'**
  String get technicianRequiredEquipment;

  /// No description provided for @technicianPreInspectionSetup.
  ///
  /// In en, this message translates to:
  /// **'PRE-INSPECTION SETUP'**
  String get technicianPreInspectionSetup;

  /// No description provided for @technicianEquipmentVerified.
  ///
  /// In en, this message translates to:
  /// **'{verified} of {total} Verified'**
  String technicianEquipmentVerified(int verified, int total);

  /// No description provided for @technicianEquipmentIntro.
  ///
  /// In en, this message translates to:
  /// **'Ensure all diagnostic hardware is calibrated and paired before starting the inspection.'**
  String get technicianEquipmentIntro;

  /// No description provided for @technicianEquipmentStandards.
  ///
  /// In en, this message translates to:
  /// **'Workshop equipment standards'**
  String get technicianEquipmentStandards;

  /// No description provided for @technicianEquipmentNameUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Name unavailable'**
  String get technicianEquipmentNameUnavailable;

  /// No description provided for @technicianHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Intake Hub'**
  String get technicianHubTitle;

  /// No description provided for @technicianChecksDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'CHECKS DONE'**
  String get technicianChecksDoneLabel;

  /// No description provided for @technicianQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get technicianQueued;

  /// No description provided for @technicianNoConditionScore.
  ///
  /// In en, this message translates to:
  /// **'No condition score'**
  String get technicianNoConditionScore;

  /// No description provided for @technicianVinChassis.
  ///
  /// In en, this message translates to:
  /// **'VIN / Chassis'**
  String get technicianVinChassis;

  /// No description provided for @technicianCustomerChip.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get technicianCustomerChip;

  /// No description provided for @technicianCall.
  ///
  /// In en, this message translates to:
  /// **'Call customer'**
  String get technicianCall;

  /// No description provided for @technicianMessage.
  ///
  /// In en, this message translates to:
  /// **'Message customer'**
  String get technicianMessage;

  /// No description provided for @technicianServicePackage.
  ///
  /// In en, this message translates to:
  /// **'Service Package'**
  String get technicianServicePackage;

  /// No description provided for @technicianJobDetailsReady.
  ///
  /// In en, this message translates to:
  /// **'Job details ready'**
  String get technicianJobDetailsReady;

  /// No description provided for @technicianInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get technicianInspection;

  /// No description provided for @technicianConsentStep.
  ///
  /// In en, this message translates to:
  /// **'CONSENT • FINAL STEP'**
  String get technicianConsentStep;

  /// No description provided for @technicianConsentDecision.
  ///
  /// In en, this message translates to:
  /// **'Consent decision'**
  String get technicianConsentDecision;

  /// No description provided for @technicianNoSignature.
  ///
  /// In en, this message translates to:
  /// **'No signature captured'**
  String get technicianNoSignature;

  /// No description provided for @technicianAuthorizedRepresentative.
  ///
  /// In en, this message translates to:
  /// **'Authorized representative'**
  String get technicianAuthorizedRepresentative;

  /// No description provided for @technicianConsentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose Granted or Refused'**
  String get technicianConsentHint;

  /// No description provided for @technicianDataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data storage'**
  String get technicianDataStorage;

  /// No description provided for @technicianUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available in this version'**
  String get technicianUnavailable;

  /// No description provided for @technicianTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get technicianTimestamp;

  /// No description provided for @technicianClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get technicianClear;

  /// No description provided for @technicianSecurityLine.
  ///
  /// In en, this message translates to:
  /// **'Authorised workshop staff only'**
  String get technicianSecurityLine;

  /// No description provided for @technicianEquipmentStandardsBody.
  ///
  /// In en, this message translates to:
  /// **'Equipment availability is confirmed by the workshop.'**
  String get technicianEquipmentStandardsBody;

  /// No description provided for @technicianProceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get technicianProceed;

  /// No description provided for @technicianItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String technicianItemsCount(int count);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start inspecting vehicles with TrueReport\'s precision diagnostic suite.'**
  String get signUpSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get passwordStrength;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordStrengthFair;

  /// No description provided for @passwordStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordStrengthGood;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get termsAgreement;

  /// No description provided for @termsRequired.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and conditions to proceed.'**
  String get termsRequired;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpButton;

  /// No description provided for @featureBadge.
  ///
  /// In en, this message translates to:
  /// **'PRECISION DIAGNOSTICS'**
  String get featureBadge;

  /// No description provided for @featureHeadline.
  ///
  /// In en, this message translates to:
  /// **'Enterprise Condition Assessment & Audit-Proof Reports'**
  String get featureHeadline;

  /// No description provided for @featureSubhead.
  ///
  /// In en, this message translates to:
  /// **'Powering automotive workshops with immutable condition logs, instant customer delivery, and real-time offline sync.'**
  String get featureSubhead;

  /// No description provided for @statInspectionCount.
  ///
  /// In en, this message translates to:
  /// **'250K+'**
  String get statInspectionCount;

  /// No description provided for @statInspectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicles inspected'**
  String get statInspectionLabel;

  /// No description provided for @statAccuracy.
  ///
  /// In en, this message translates to:
  /// **'99.8%'**
  String get statAccuracy;

  /// No description provided for @statAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic accuracy'**
  String get statAccuracyLabel;

  /// No description provided for @statSyncSpeed.
  ///
  /// In en, this message translates to:
  /// **'Real-time'**
  String get statSyncSpeed;

  /// No description provided for @statSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline-first sync'**
  String get statSyncLabel;

  /// No description provided for @technicianExteriorInspection.
  ///
  /// In en, this message translates to:
  /// **'EXTERIOR INSPECTION'**
  String get technicianExteriorInspection;

  /// No description provided for @technicianDetectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Detected} other{{count} Detected}}'**
  String technicianDetectedCount(int count);

  /// No description provided for @technicianExteriorStep2.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Tap the area to\ncapture damage'**
  String get technicianExteriorStep2;

  /// No description provided for @technicianExteriorHint.
  ///
  /// In en, this message translates to:
  /// **'Pin scratches, dents, or paint chips directly on the\nwireframe schematic.'**
  String get technicianExteriorHint;

  /// No description provided for @technicianAnglePerspective.
  ///
  /// In en, this message translates to:
  /// **'ANGLE PERSPECTIVE'**
  String get technicianAnglePerspective;

  /// No description provided for @technicianTapToRotate.
  ///
  /// In en, this message translates to:
  /// **'Tap to rotate 360°'**
  String get technicianTapToRotate;

  /// No description provided for @technicianPerspectiveFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get technicianPerspectiveFront;

  /// No description provided for @technicianPerspectiveDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get technicianPerspectiveDriver;

  /// No description provided for @technicianPerspectivePassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get technicianPerspectivePassenger;

  /// No description provided for @technicianPerspectiveRear.
  ///
  /// In en, this message translates to:
  /// **'Rear'**
  String get technicianPerspectiveRear;

  /// No description provided for @technicianConfirmExteriorMarkup.
  ///
  /// In en, this message translates to:
  /// **'Confirm Exterior Markup'**
  String get technicianConfirmExteriorMarkup;

  /// No description provided for @technicianNoDamageOnPanel.
  ///
  /// In en, this message translates to:
  /// **'No Damage Found on this Panel'**
  String get technicianNoDamageOnPanel;

  /// No description provided for @technicianDriverSideView.
  ///
  /// In en, this message translates to:
  /// **'DRIVER SIDE VIEW'**
  String get technicianDriverSideView;

  /// No description provided for @technicianWalkaroundInspection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Walkaround Inspection'**
  String get technicianWalkaroundInspection;

  /// No description provided for @technicianDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get technicianDraw;

  /// No description provided for @technicianUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get technicianUndo;

  /// No description provided for @technicianCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get technicianCrop;

  /// No description provided for @technicianSavePhoto.
  ///
  /// In en, this message translates to:
  /// **'Save Photo'**
  String get technicianSavePhoto;

  /// No description provided for @technicianVinEnding.
  ///
  /// In en, this message translates to:
  /// **'VIN ENDING'**
  String get technicianVinEnding;

  /// No description provided for @technicianItemsChecked.
  ///
  /// In en, this message translates to:
  /// **'ITEMS CHECKED'**
  String get technicianItemsChecked;

  /// No description provided for @technicianPdfSize.
  ///
  /// In en, this message translates to:
  /// **'PDF SIZE'**
  String get technicianPdfSize;

  /// No description provided for @technicianBackToJobList.
  ///
  /// In en, this message translates to:
  /// **'Back to Job List'**
  String get technicianBackToJobList;

  /// No description provided for @technicianTireFl.
  ///
  /// In en, this message translates to:
  /// **'FL'**
  String get technicianTireFl;

  /// No description provided for @technicianTireFr.
  ///
  /// In en, this message translates to:
  /// **'FR'**
  String get technicianTireFr;

  /// No description provided for @technicianTireRr.
  ///
  /// In en, this message translates to:
  /// **'RR'**
  String get technicianTireRr;

  /// No description provided for @technicianSaveAction.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get technicianSaveAction;

  /// No description provided for @adminFeatureTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Live Bay Telemetry & Queue'**
  String get adminFeatureTelemetry;

  /// No description provided for @adminFeatureSop.
  ///
  /// In en, this message translates to:
  /// **'Adaptive SOP Builder'**
  String get adminFeatureSop;

  /// No description provided for @adminFeatureAudit.
  ///
  /// In en, this message translates to:
  /// **'Cryptographic Audit Clearance'**
  String get adminFeatureAudit;

  /// No description provided for @adminFeatureHierarchy.
  ///
  /// In en, this message translates to:
  /// **'Workshop Management'**
  String get adminFeatureHierarchy;

  /// No description provided for @adminFeatureCatalog.
  ///
  /// In en, this message translates to:
  /// **'Checklist Library'**
  String get adminFeatureCatalog;

  /// No description provided for @adminFeatureLedger.
  ///
  /// In en, this message translates to:
  /// **'Immutable Security Ledger'**
  String get adminFeatureLedger;

  /// No description provided for @masterLibrary.
  ///
  /// In en, this message translates to:
  /// **'Master Library'**
  String get masterLibrary;

  /// No description provided for @dataCatalogues.
  ///
  /// In en, this message translates to:
  /// **'Data Catalogues'**
  String get dataCatalogues;

  /// No description provided for @auditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditLog;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @vehicleMakes.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Makes'**
  String get vehicleMakes;

  /// No description provided for @defectSeverities.
  ///
  /// In en, this message translates to:
  /// **'Defect Severities'**
  String get defectSeverities;

  /// No description provided for @notCheckedReasons.
  ///
  /// In en, this message translates to:
  /// **'Not-Checked Reasons'**
  String get notCheckedReasons;

  /// No description provided for @fuelPowertrainTypes.
  ///
  /// In en, this message translates to:
  /// **'Fuel & Powertrain Types'**
  String get fuelPowertrainTypes;

  /// No description provided for @fluidSpecifications.
  ///
  /// In en, this message translates to:
  /// **'Fluid Specifications'**
  String get fluidSpecifications;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @totalJobs.
  ///
  /// In en, this message translates to:
  /// **'Total Jobs'**
  String get totalJobs;

  /// No description provided for @workshopAdminName.
  ///
  /// In en, this message translates to:
  /// **'Workshop Admin Name'**
  String get workshopAdminName;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get contactPhone;

  /// No description provided for @technicianDispatchClearance.
  ///
  /// In en, this message translates to:
  /// **'Technician Dispatch Clearance'**
  String get technicianDispatchClearance;

  /// No description provided for @diagnosticOverrideAuthority.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic Override Authority'**
  String get diagnosticOverrideAuthority;

  /// No description provided for @telemetryIngestionKey.
  ///
  /// In en, this message translates to:
  /// **'Telemetry Ingestion Key'**
  String get telemetryIngestionKey;

  /// No description provided for @registerWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Register Workshop'**
  String get registerWorkshop;

  /// No description provided for @detailsAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Details & Settings'**
  String get detailsAndSettings;

  /// No description provided for @registerAndProvision.
  ///
  /// In en, this message translates to:
  /// **'Register & Provision'**
  String get registerAndProvision;

  /// No description provided for @preferencesReset.
  ///
  /// In en, this message translates to:
  /// **'Preferences reset to default values.'**
  String get preferencesReset;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Platform preferences saved and propagated to edge nodes!'**
  String get preferencesSaved;

  /// No description provided for @enableArabicRtl.
  ///
  /// In en, this message translates to:
  /// **'Enable Arabic (RTL) Localization'**
  String get enableArabicRtl;

  /// No description provided for @enableArabicRtlDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-reverses layout coordinates and inspector forms'**
  String get enableArabicRtlDesc;

  /// No description provided for @enableSpanish.
  ///
  /// In en, this message translates to:
  /// **'Enable Spanish Support'**
  String get enableSpanish;

  /// No description provided for @enableSpanishDesc.
  ///
  /// In en, this message translates to:
  /// **'Workshop regional standard (es-MX / es-ES)'**
  String get enableSpanishDesc;

  /// No description provided for @enableFrench.
  ///
  /// In en, this message translates to:
  /// **'Enable French Support'**
  String get enableFrench;

  /// No description provided for @enableFrenchDesc.
  ///
  /// In en, this message translates to:
  /// **'Quebec & European fleet inspection checklists'**
  String get enableFrenchDesc;

  /// No description provided for @enforce2fa.
  ///
  /// In en, this message translates to:
  /// **'Enforce 2FA (TOTP) for All Admins'**
  String get enforce2fa;

  /// No description provided for @enforce2faDesc.
  ///
  /// In en, this message translates to:
  /// **'Mandatory hardware security key or authenticator app'**
  String get enforce2faDesc;

  /// No description provided for @ipWhitelist.
  ///
  /// In en, this message translates to:
  /// **'IP Restriction Whitelist'**
  String get ipWhitelist;

  /// No description provided for @ipWhitelistDesc.
  ///
  /// In en, this message translates to:
  /// **'Limit console access strictly to corporate diagnostic VPNs'**
  String get ipWhitelistDesc;

  /// No description provided for @subsystem.
  ///
  /// In en, this message translates to:
  /// **'SUBSYSTEM'**
  String get subsystem;

  /// No description provided for @measurementMetric.
  ///
  /// In en, this message translates to:
  /// **'MEASUREMENT METRIC'**
  String get measurementMetric;

  /// No description provided for @masterCheckpointSaved.
  ///
  /// In en, this message translates to:
  /// **'Master checkpoint specification saved and broadcasted.'**
  String get masterCheckpointSaved;

  /// No description provided for @fifteenMinutes.
  ///
  /// In en, this message translates to:
  /// **'15 Minutes'**
  String get fifteenMinutes;

  /// No description provided for @thirtyMinutes.
  ///
  /// In en, this message translates to:
  /// **'30 Minutes'**
  String get thirtyMinutes;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 Hour'**
  String get oneHour;

  /// No description provided for @fourHours.
  ///
  /// In en, this message translates to:
  /// **'4 Hours'**
  String get fourHours;

  /// No description provided for @navTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get navTemplates;

  /// No description provided for @navScoring.
  ///
  /// In en, this message translates to:
  /// **'Scoring'**
  String get navScoring;

  /// No description provided for @navDocumentTypes.
  ///
  /// In en, this message translates to:
  /// **'Document Types'**
  String get navDocumentTypes;

  /// No description provided for @navLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get navLanguages;

  /// No description provided for @navConfigHealth.
  ///
  /// In en, this message translates to:
  /// **'Config Health'**
  String get navConfigHealth;

  /// No description provided for @navConfigurationSection.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get navConfigurationSection;

  /// No description provided for @navChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get navChecklist;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @checklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklistTitle;

  /// No description provided for @checklistHelper.
  ///
  /// In en, this message translates to:
  /// **'The Checklist is the reusable master catalog. Templates are named sets of checklist categories and items that workshops select when creating jobs.'**
  String get checklistHelper;

  /// No description provided for @checklistTabTemplates.
  ///
  /// In en, this message translates to:
  /// **'Inspection Templates'**
  String get checklistTabTemplates;

  /// No description provided for @checklistTabIssueOptions.
  ///
  /// In en, this message translates to:
  /// **'Issue Options'**
  String get checklistTabIssueOptions;

  /// No description provided for @checklistTabHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get checklistTabHealth;

  /// No description provided for @templateHelper.
  ///
  /// In en, this message translates to:
  /// **'A template is a reusable set of categories and items from the Checklist. Workshop Admin selects it when creating a job.'**
  String get templateHelper;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportDocuments.
  ///
  /// In en, this message translates to:
  /// **'Report Documents'**
  String get reportDocuments;

  /// No description provided for @languagesCoverage.
  ///
  /// In en, this message translates to:
  /// **'Languages & Coverage'**
  String get languagesCoverage;

  /// No description provided for @checklistHealth.
  ///
  /// In en, this message translates to:
  /// **'Checklist Health'**
  String get checklistHealth;

  /// No description provided for @reviewHealth.
  ///
  /// In en, this message translates to:
  /// **'Review health'**
  String get reviewHealth;

  /// No description provided for @masterLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Master Library'**
  String get masterLibraryTitle;

  /// No description provided for @masterLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Centrally governed inspection configuration for every workshop'**
  String get masterLibrarySubtitle;

  /// No description provided for @seedDefaultChecklist.
  ///
  /// In en, this message translates to:
  /// **'Load default checklist'**
  String get seedDefaultChecklist;

  /// No description provided for @seedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Load the default checklist now? Existing records are kept and skipped.'**
  String get seedConfirm;

  /// No description provided for @seedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Seed completed: {created} created, {skipped} skipped'**
  String seedSuccess(int created, int skipped);

  /// No description provided for @seedFailed.
  ///
  /// In en, this message translates to:
  /// **'Seed failed'**
  String get seedFailed;

  /// No description provided for @categoriesTab.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTab;

  /// No description provided for @itemsTab.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsTab;

  /// No description provided for @optionSetsTab.
  ///
  /// In en, this message translates to:
  /// **'Option sets'**
  String get optionSetsTab;

  /// No description provided for @categoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category management'**
  String get categoryManagement;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @categoryCode.
  ///
  /// In en, this message translates to:
  /// **'Category code'**
  String get categoryCode;

  /// No description provided for @categoryWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight %'**
  String get categoryWeight;

  /// No description provided for @categoryOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get categoryOrder;

  /// No description provided for @weightTotal.
  ///
  /// In en, this message translates to:
  /// **'Weight total'**
  String get weightTotal;

  /// No description provided for @weightsValid.
  ///
  /// In en, this message translates to:
  /// **'Active weights sum to 100'**
  String get weightsValid;

  /// No description provided for @weightsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Active weights must sum to 100'**
  String get weightsInvalid;

  /// No description provided for @retireCategory.
  ///
  /// In en, this message translates to:
  /// **'Retire category'**
  String get retireCategory;

  /// No description provided for @retireConfirm.
  ///
  /// In en, this message translates to:
  /// **'Retire this record? Referenced records cannot be deleted, only retired.'**
  String get retireConfirm;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @itemEditor.
  ///
  /// In en, this message translates to:
  /// **'Item editor'**
  String get itemEditor;

  /// No description provided for @basics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get basics;

  /// No description provided for @englishContent.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishContent;

  /// No description provided for @arabicContent.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabicContent;

  /// No description provided for @scoreBands.
  ///
  /// In en, this message translates to:
  /// **'Score bands'**
  String get scoreBands;

  /// No description provided for @evidenceRules.
  ///
  /// In en, this message translates to:
  /// **'Evidence rules'**
  String get evidenceRules;

  /// No description provided for @issueFields.
  ///
  /// In en, this message translates to:
  /// **'Issue fields'**
  String get issueFields;

  /// No description provided for @measurementBands.
  ///
  /// In en, this message translates to:
  /// **'Measurement bands'**
  String get measurementBands;

  /// No description provided for @itemCode.
  ///
  /// In en, this message translates to:
  /// **'Item code'**
  String get itemCode;

  /// No description provided for @measurementUnit.
  ///
  /// In en, this message translates to:
  /// **'Measurement unit'**
  String get measurementUnit;

  /// No description provided for @sensorTool.
  ///
  /// In en, this message translates to:
  /// **'Sensor / tool'**
  String get sensorTool;

  /// No description provided for @standardSpecEn.
  ///
  /// In en, this message translates to:
  /// **'Standard spec (English)'**
  String get standardSpecEn;

  /// No description provided for @standardSpecAr.
  ///
  /// In en, this message translates to:
  /// **'Standard spec (Arabic)'**
  String get standardSpecAr;

  /// No description provided for @multiPoint.
  ///
  /// In en, this message translates to:
  /// **'Multi-point item'**
  String get multiPoint;

  /// No description provided for @maxTyreAge.
  ///
  /// In en, this message translates to:
  /// **'Max tyre age (years)'**
  String get maxTyreAge;

  /// No description provided for @allowFreeText.
  ///
  /// In en, this message translates to:
  /// **'Allow free-text note'**
  String get allowFreeText;

  /// No description provided for @minVideos.
  ///
  /// In en, this message translates to:
  /// **'Min videos'**
  String get minVideos;

  /// No description provided for @minNotes.
  ///
  /// In en, this message translates to:
  /// **'Min note characters'**
  String get minNotes;

  /// No description provided for @requiredEvidenceType.
  ///
  /// In en, this message translates to:
  /// **'Required evidence type'**
  String get requiredEvidenceType;

  /// No description provided for @minValue.
  ///
  /// In en, this message translates to:
  /// **'Min value'**
  String get minValue;

  /// No description provided for @maxValue.
  ///
  /// In en, this message translates to:
  /// **'Max value'**
  String get maxValue;

  /// No description provided for @criteriaEn.
  ///
  /// In en, this message translates to:
  /// **'Criteria (English)'**
  String get criteriaEn;

  /// No description provided for @criteriaAr.
  ///
  /// In en, this message translates to:
  /// **'Criteria (Arabic)'**
  String get criteriaAr;

  /// No description provided for @fieldCode.
  ///
  /// In en, this message translates to:
  /// **'Field code'**
  String get fieldCode;

  /// No description provided for @inputType.
  ///
  /// In en, this message translates to:
  /// **'Input type'**
  String get inputType;

  /// No description provided for @optionSet.
  ///
  /// In en, this message translates to:
  /// **'Option set'**
  String get optionSet;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @dependsOn.
  ///
  /// In en, this message translates to:
  /// **'Depends on'**
  String get dependsOn;

  /// No description provided for @allowMultiple.
  ///
  /// In en, this message translates to:
  /// **'Allow multiple'**
  String get allowMultiple;

  /// No description provided for @allowedValues.
  ///
  /// In en, this message translates to:
  /// **'Allowed values'**
  String get allowedValues;

  /// No description provided for @requiredForStatuses.
  ///
  /// In en, this message translates to:
  /// **'Required for statuses'**
  String get requiredForStatuses;

  /// No description provided for @decimalPlaces.
  ///
  /// In en, this message translates to:
  /// **'Decimal places'**
  String get decimalPlaces;

  /// No description provided for @publishItem.
  ///
  /// In en, this message translates to:
  /// **'Publish item'**
  String get publishItem;

  /// No description provided for @itemPublished.
  ///
  /// In en, this message translates to:
  /// **'Item version published'**
  String get itemPublished;

  /// No description provided for @versionImmutable.
  ///
  /// In en, this message translates to:
  /// **'Published versions are immutable. Create a draft to edit.'**
  String get versionImmutable;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @addOptionSet.
  ///
  /// In en, this message translates to:
  /// **'Add option set'**
  String get addOptionSet;

  /// No description provided for @itemCreated.
  ///
  /// In en, this message translates to:
  /// **'Item created'**
  String get itemCreated;

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create template'**
  String get createTemplate;

  /// No description provided for @templateCode.
  ///
  /// In en, this message translates to:
  /// **'Template code'**
  String get templateCode;

  /// No description provided for @templateNameEn.
  ///
  /// In en, this message translates to:
  /// **'Template name (English)'**
  String get templateNameEn;

  /// No description provided for @templateNameAr.
  ///
  /// In en, this message translates to:
  /// **'Template name (Arabic)'**
  String get templateNameAr;

  /// No description provided for @templateDescriptionEn.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get templateDescriptionEn;

  /// No description provided for @templateDescriptionAr.
  ///
  /// In en, this message translates to:
  /// **'Description (Arabic)'**
  String get templateDescriptionAr;

  /// No description provided for @templateBuilder.
  ///
  /// In en, this message translates to:
  /// **'Template builder'**
  String get templateBuilder;

  /// No description provided for @weightPreview.
  ///
  /// In en, this message translates to:
  /// **'Weight preview'**
  String get weightPreview;

  /// No description provided for @normalizedWeight.
  ///
  /// In en, this message translates to:
  /// **'Normalized weight'**
  String get normalizedWeight;

  /// No description provided for @approveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveTemplate;

  /// No description provided for @rejectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectTemplate;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get pendingApproval;

  /// No description provided for @scoringRules.
  ///
  /// In en, this message translates to:
  /// **'Scoring rules'**
  String get scoringRules;

  /// No description provided for @categoryWeightMode.
  ///
  /// In en, this message translates to:
  /// **'Category weight mode'**
  String get categoryWeightMode;

  /// No description provided for @safetyCap.
  ///
  /// In en, this message translates to:
  /// **'Safety cap'**
  String get safetyCap;

  /// No description provided for @capGrade.
  ///
  /// In en, this message translates to:
  /// **'Cap grade'**
  String get capGrade;

  /// No description provided for @gradeBoundaries.
  ///
  /// In en, this message translates to:
  /// **'Grade boundaries'**
  String get gradeBoundaries;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @addGrade.
  ///
  /// In en, this message translates to:
  /// **'Add grade'**
  String get addGrade;

  /// No description provided for @coverageValid.
  ///
  /// In en, this message translates to:
  /// **'Grade boundaries cover 0-100'**
  String get coverageValid;

  /// No description provided for @coverageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Grade boundaries must cover 0-100 without gaps'**
  String get coverageInvalid;

  /// No description provided for @proposeChange.
  ///
  /// In en, this message translates to:
  /// **'Propose change'**
  String get proposeChange;

  /// No description provided for @approveChange.
  ///
  /// In en, this message translates to:
  /// **'Approve change'**
  String get approveChange;

  /// No description provided for @documentTypes.
  ///
  /// In en, this message translates to:
  /// **'Report document types'**
  String get documentTypes;

  /// No description provided for @addDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Add document type'**
  String get addDocumentType;

  /// No description provided for @documentTypeCode.
  ///
  /// In en, this message translates to:
  /// **'Document type code'**
  String get documentTypeCode;

  /// No description provided for @languageRegistry.
  ///
  /// In en, this message translates to:
  /// **'Language registry'**
  String get languageRegistry;

  /// No description provided for @addLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add language'**
  String get addLanguage;

  /// No description provided for @languageCode.
  ///
  /// In en, this message translates to:
  /// **'Language code'**
  String get languageCode;

  /// No description provided for @nativeName.
  ///
  /// In en, this message translates to:
  /// **'Native name'**
  String get nativeName;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @defaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default language'**
  String get defaultLanguage;

  /// No description provided for @translationCoverage.
  ///
  /// In en, this message translates to:
  /// **'Translation coverage'**
  String get translationCoverage;

  /// No description provided for @missingTranslations.
  ///
  /// In en, this message translates to:
  /// **'Missing translations'**
  String get missingTranslations;

  /// No description provided for @configHealth.
  ///
  /// In en, this message translates to:
  /// **'Configuration health'**
  String get configHealth;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @unhealthy.
  ///
  /// In en, this message translates to:
  /// **'Issues found'**
  String get unhealthy;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @impactAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Impact analysis'**
  String get impactAnalysis;

  /// No description provided for @affectedTemplates.
  ///
  /// In en, this message translates to:
  /// **'Affected templates'**
  String get affectedTemplates;

  /// No description provided for @affectedItems.
  ///
  /// In en, this message translates to:
  /// **'Affected items'**
  String get affectedItems;

  /// No description provided for @affectedJobs.
  ///
  /// In en, this message translates to:
  /// **'Affected jobs'**
  String get affectedJobs;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @notBlocked.
  ///
  /// In en, this message translates to:
  /// **'Not blocked'**
  String get notBlocked;

  /// No description provided for @configReleases.
  ///
  /// In en, this message translates to:
  /// **'Config releases'**
  String get configReleases;

  /// No description provided for @createRelease.
  ///
  /// In en, this message translates to:
  /// **'Create release'**
  String get createRelease;

  /// No description provided for @renameTemplate.
  ///
  /// In en, this message translates to:
  /// **'Rename template'**
  String get renameTemplate;

  /// No description provided for @releaseEntityType.
  ///
  /// In en, this message translates to:
  /// **'Entity type'**
  String get releaseEntityType;

  /// No description provided for @releaseEntityId.
  ///
  /// In en, this message translates to:
  /// **'Entity ID'**
  String get releaseEntityId;

  /// No description provided for @releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release notes'**
  String get releaseNotes;

  /// No description provided for @releaseSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get releaseSubmit;

  /// No description provided for @releaseApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve release'**
  String get releaseApprove;

  /// No description provided for @releasePublish.
  ///
  /// In en, this message translates to:
  /// **'Publish release'**
  String get releasePublish;

  /// No description provided for @releaseDeprecate.
  ///
  /// In en, this message translates to:
  /// **'Deprecate release'**
  String get releaseDeprecate;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @jobsBoardTab.
  ///
  /// In en, this message translates to:
  /// **'Job board'**
  String get jobsBoardTab;

  /// No description provided for @jobsNotificationsTab.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get jobsNotificationsTab;

  /// No description provided for @jobsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification center'**
  String get jobsNotificationsTitle;

  /// No description provided for @jobsNotificationsUnreadOnly.
  ///
  /// In en, this message translates to:
  /// **'Unread only'**
  String get jobsNotificationsUnreadOnly;

  /// No description provided for @jobsNotificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get jobsNotificationsEmpty;

  /// No description provided for @jobsNotificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get jobsNotificationsMarkRead;

  /// No description provided for @jobsNotificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'Notification marked as read'**
  String get jobsNotificationsMarkedRead;

  /// No description provided for @jobsNotificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get jobsNotificationsUnread;

  /// No description provided for @jobsNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get jobsNotificationsRead;

  /// No description provided for @jobsCountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Job counts'**
  String get jobsCountsTitle;

  /// No description provided for @jobsCountDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get jobsCountDraft;

  /// No description provided for @jobsCountScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get jobsCountScheduled;

  /// No description provided for @jobsCountAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get jobsCountAssigned;

  /// No description provided for @jobsCountInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get jobsCountInProgress;

  /// No description provided for @jobsCountPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get jobsCountPendingReview;

  /// No description provided for @jobsCountApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get jobsCountApproved;

  /// No description provided for @jobsCountPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get jobsCountPublished;

  /// No description provided for @jobsCountRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get jobsCountRejected;

  /// No description provided for @jobsCountCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get jobsCountCancelled;

  /// No description provided for @jobsCountTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get jobsCountTotal;

  /// No description provided for @jobsStatusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get jobsStatusPendingReview;

  /// No description provided for @jobsStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get jobsStatusApproved;

  /// No description provided for @jobsStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get jobsStatusPublished;

  /// No description provided for @jobsStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get jobsStatusRejected;

  /// No description provided for @commonPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get commonPage;

  /// No description provided for @commonOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get commonOf;

  /// No description provided for @commonPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get commonPrevious;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @jobsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get jobsEmpty;

  /// No description provided for @jobsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create job'**
  String get jobsCreateTitle;

  /// No description provided for @jobsCreateStepCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get jobsCreateStepCustomer;

  /// No description provided for @jobsCreateStepVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get jobsCreateStepVehicle;

  /// No description provided for @jobsCreateStepTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get jobsCreateStepTemplate;

  /// No description provided for @jobsCreateStepTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get jobsCreateStepTechnician;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @jobsCreateCta.
  ///
  /// In en, this message translates to:
  /// **'Create job'**
  String get jobsCreateCta;

  /// No description provided for @jobsFieldOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get jobsFieldOdometer;

  /// No description provided for @jobsFieldOdometerUnit.
  ///
  /// In en, this message translates to:
  /// **'Odometer unit'**
  String get jobsFieldOdometerUnit;

  /// No description provided for @jobsFieldTransmission.
  ///
  /// In en, this message translates to:
  /// **'Transmission'**
  String get jobsFieldTransmission;

  /// No description provided for @jobsFieldFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get jobsFieldFuelType;

  /// No description provided for @jobsFieldPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get jobsFieldPreferredLanguage;

  /// No description provided for @jobsTemplatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available templates'**
  String get jobsTemplatesAvailable;

  /// No description provided for @jobsTemplatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No published templates available'**
  String get jobsTemplatesEmpty;

  /// No description provided for @jobsSelectTechnician.
  ///
  /// In en, this message translates to:
  /// **'Select technician'**
  String get jobsSelectTechnician;

  /// No description provided for @jobsAssignLater.
  ///
  /// In en, this message translates to:
  /// **'Assign later'**
  String get jobsAssignLater;

  /// No description provided for @jobsCreated.
  ///
  /// In en, this message translates to:
  /// **'Job created'**
  String get jobsCreated;

  /// No description provided for @commonServerRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected this request.'**
  String get commonServerRejected;

  /// No description provided for @jobsValidationVin.
  ///
  /// In en, this message translates to:
  /// **'VIN must be 17 characters.'**
  String get jobsValidationVin;

  /// No description provided for @jobsValidationPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer phone is required.'**
  String get jobsValidationPhoneRequired;

  /// No description provided for @jobsValidationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get jobsValidationEmailInvalid;

  /// No description provided for @jobsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get jobsDetailTitle;

  /// No description provided for @jobsSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get jobsSummary;

  /// No description provided for @jobsAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get jobsAssignmentsTitle;

  /// No description provided for @jobsAssignmentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assignments yet'**
  String get jobsAssignmentsEmpty;

  /// No description provided for @jobsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get jobsReviewTitle;

  /// No description provided for @jobsReviewStatus.
  ///
  /// In en, this message translates to:
  /// **'Review status'**
  String get jobsReviewStatus;

  /// No description provided for @jobsPublicationStatus.
  ///
  /// In en, this message translates to:
  /// **'Publication status'**
  String get jobsPublicationStatus;

  /// No description provided for @jobsItemsAssessed.
  ///
  /// In en, this message translates to:
  /// **'Items assessed'**
  String get jobsItemsAssessed;

  /// No description provided for @jobsScorePreview.
  ///
  /// In en, this message translates to:
  /// **'Score preview'**
  String get jobsScorePreview;

  /// No description provided for @jobsGradePreview.
  ///
  /// In en, this message translates to:
  /// **'Grade preview'**
  String get jobsGradePreview;

  /// No description provided for @jobsSafetyCapPreview.
  ///
  /// In en, this message translates to:
  /// **'Safety cap preview'**
  String get jobsSafetyCapPreview;

  /// No description provided for @jobsScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get jobsScore;

  /// No description provided for @jobsEvidencePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get jobsEvidencePhotos;

  /// No description provided for @jobsEvidenceVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get jobsEvidenceVideos;

  /// No description provided for @jobsSignaturePresent.
  ///
  /// In en, this message translates to:
  /// **'Signature present'**
  String get jobsSignaturePresent;

  /// No description provided for @jobsSignatureMissing.
  ///
  /// In en, this message translates to:
  /// **'Signature missing'**
  String get jobsSignatureMissing;

  /// No description provided for @jobsCompletedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed at'**
  String get jobsCompletedAt;

  /// No description provided for @jobsIssueValues.
  ///
  /// In en, this message translates to:
  /// **'Issue values'**
  String get jobsIssueValues;

  /// No description provided for @jobsNoFindings.
  ///
  /// In en, this message translates to:
  /// **'No findings'**
  String get jobsNoFindings;

  /// No description provided for @jobsOpenReview.
  ///
  /// In en, this message translates to:
  /// **'Open review'**
  String get jobsOpenReview;

  /// No description provided for @jobsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get jobsApprove;

  /// No description provided for @jobsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get jobsReject;

  /// No description provided for @jobsApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve and issue certificate'**
  String get jobsApproveTitle;

  /// No description provided for @jobsApproveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the score, grade and checklist before approving.'**
  String get jobsApproveSubtitle;

  /// No description provided for @jobsSafetyCritical.
  ///
  /// In en, this message translates to:
  /// **'Safety critical'**
  String get jobsSafetyCritical;

  /// No description provided for @jobsSafetyCapReason.
  ///
  /// In en, this message translates to:
  /// **'Safety cap reason'**
  String get jobsSafetyCapReason;

  /// No description provided for @jobsApproved.
  ///
  /// In en, this message translates to:
  /// **'Job approved'**
  String get jobsApproved;

  /// No description provided for @jobsRejected.
  ///
  /// In en, this message translates to:
  /// **'Job rejected'**
  String get jobsRejected;

  /// No description provided for @jobsRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get jobsRejectReason;

  /// No description provided for @jobsRejectHint.
  ///
  /// In en, this message translates to:
  /// **'Rejection closes the job and requires a new inspection.'**
  String get jobsRejectHint;

  /// No description provided for @jobsApproveReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Approval reason (optional)'**
  String get jobsApproveReasonOptional;

  /// No description provided for @jobsOpenPublishChecklist.
  ///
  /// In en, this message translates to:
  /// **'Open publish checklist'**
  String get jobsOpenPublishChecklist;

  /// No description provided for @jobsPublishChecklist.
  ///
  /// In en, this message translates to:
  /// **'Publish checklist'**
  String get jobsPublishChecklist;

  /// No description provided for @jobsChecklistReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to publish'**
  String get jobsChecklistReady;

  /// No description provided for @jobsChecklistNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready to publish'**
  String get jobsChecklistNotReady;

  /// No description provided for @jobsChecklistPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get jobsChecklistPassed;

  /// No description provided for @jobsChecklistFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get jobsChecklistFailed;

  /// No description provided for @jobsConsentGranted.
  ///
  /// In en, this message translates to:
  /// **'Consent granted'**
  String get jobsConsentGranted;

  /// No description provided for @jobsConsentMissing.
  ///
  /// In en, this message translates to:
  /// **'Consent missing'**
  String get jobsConsentMissing;

  /// No description provided for @jobsDocumentsReady.
  ///
  /// In en, this message translates to:
  /// **'Documents ready'**
  String get jobsDocumentsReady;

  /// No description provided for @jobsDocumentsNotReady.
  ///
  /// In en, this message translates to:
  /// **'Documents not ready'**
  String get jobsDocumentsNotReady;

  /// No description provided for @jobsSafetyCapApplied.
  ///
  /// In en, this message translates to:
  /// **'Safety cap applied'**
  String get jobsSafetyCapApplied;

  /// No description provided for @jobsSafetyCapNotApplied.
  ///
  /// In en, this message translates to:
  /// **'No safety cap'**
  String get jobsSafetyCapNotApplied;

  /// No description provided for @jobsGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get jobsGrade;

  /// No description provided for @jobsPublishNow.
  ///
  /// In en, this message translates to:
  /// **'Publish report'**
  String get jobsPublishNow;

  /// No description provided for @jobsPublished.
  ///
  /// In en, this message translates to:
  /// **'Report published'**
  String get jobsPublished;

  /// No description provided for @jobsPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not publish.'**
  String get jobsPublishFailed;

  /// No description provided for @jobsPublicLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Public link'**
  String get jobsPublicLinkTitle;

  /// No description provided for @jobsPublicUrl.
  ///
  /// In en, this message translates to:
  /// **'Public URL'**
  String get jobsPublicUrl;

  /// No description provided for @jobsPublicToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get jobsPublicToken;

  /// No description provided for @jobsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get jobsShare;

  /// No description provided for @jobsQrTitle.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get jobsQrTitle;

  /// No description provided for @jobsQrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'QR code unavailable'**
  String get jobsQrUnavailable;

  /// No description provided for @jobsUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get jobsUnpublish;

  /// No description provided for @jobsRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get jobsRevoke;

  /// No description provided for @jobsRotateToken.
  ///
  /// In en, this message translates to:
  /// **'Rotate token'**
  String get jobsRotateToken;

  /// No description provided for @jobsUnpublishReason.
  ///
  /// In en, this message translates to:
  /// **'Unpublish reason'**
  String get jobsUnpublishReason;

  /// No description provided for @jobsRevokeReason.
  ///
  /// In en, this message translates to:
  /// **'Revoke reason'**
  String get jobsRevokeReason;

  /// No description provided for @jobsTokenRotated.
  ///
  /// In en, this message translates to:
  /// **'Token rotated'**
  String get jobsTokenRotated;

  /// No description provided for @jobsLinkUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Link unpublished'**
  String get jobsLinkUnpublished;

  /// No description provided for @jobsActivatedAt.
  ///
  /// In en, this message translates to:
  /// **'Activated at'**
  String get jobsActivatedAt;

  /// No description provided for @jobsRevokedAt.
  ///
  /// In en, this message translates to:
  /// **'Revoked at'**
  String get jobsRevokedAt;

  /// No description provided for @jobsRevocationReason.
  ///
  /// In en, this message translates to:
  /// **'Revocation reason'**
  String get jobsRevocationReason;

  /// No description provided for @jobsShareText.
  ///
  /// In en, this message translates to:
  /// **'Share this report link'**
  String get jobsShareText;

  /// No description provided for @jobsDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get jobsDocumentsTitle;

  /// No description provided for @jobsDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get jobsDocumentType;

  /// No description provided for @jobsDocumentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get jobsDocumentLanguage;

  /// No description provided for @jobsDocumentStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get jobsDocumentStatus;

  /// No description provided for @jobsDocumentSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get jobsDocumentSize;

  /// No description provided for @jobsDocumentGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get jobsDocumentGeneratedAt;

  /// No description provided for @jobsDocumentError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get jobsDocumentError;

  /// No description provided for @jobsRetryDocument.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get jobsRetryDocument;

  /// No description provided for @jobsDocumentRetried.
  ///
  /// In en, this message translates to:
  /// **'Document retry queued'**
  String get jobsDocumentRetried;

  /// No description provided for @jobsDocumentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get jobsDocumentsEmpty;

  /// No description provided for @commonDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get commonDownload;

  /// No description provided for @commonActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Try again.'**
  String get commonActionFailed;

  /// No description provided for @commonLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load. Try again.'**
  String get commonLoadFailed;

  /// No description provided for @commonReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required.'**
  String get commonReasonRequired;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @jobsNotificationPayload.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get jobsNotificationPayload;

  /// No description provided for @jobsNotificationNoPayload.
  ///
  /// In en, this message translates to:
  /// **'No details'**
  String get jobsNotificationNoPayload;

  /// No description provided for @commonType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get commonType;

  /// No description provided for @commonCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get commonCreatedAt;

  /// No description provided for @jobsReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get jobsReference;

  /// No description provided for @jobsJobScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get jobsJobScore;

  /// No description provided for @jobsJobGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get jobsJobGrade;

  /// No description provided for @jobsAssignedTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get jobsAssignedTechnician;

  /// No description provided for @jobsUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get jobsUnit;

  /// No description provided for @jobsViewChecklist.
  ///
  /// In en, this message translates to:
  /// **'View checklist'**
  String get jobsViewChecklist;

  /// No description provided for @jobsViewDocuments.
  ///
  /// In en, this message translates to:
  /// **'View documents'**
  String get jobsViewDocuments;

  /// No description provided for @jobsViewPublicLink.
  ///
  /// In en, this message translates to:
  /// **'View public link'**
  String get jobsViewPublicLink;

  /// No description provided for @jobsCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get jobsCancelReason;

  /// No description provided for @jobsAssignTechnician.
  ///
  /// In en, this message translates to:
  /// **'Assign technician'**
  String get jobsAssignTechnician;

  /// No description provided for @jobsAssignmentReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get jobsAssignmentReason;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get commonNotAvailable;

  /// No description provided for @jobsOpenJobBoard.
  ///
  /// In en, this message translates to:
  /// **'Open job board'**
  String get jobsOpenJobBoard;

  /// No description provided for @technicianJobSearch.
  ///
  /// In en, this message translates to:
  /// **'Search jobs'**
  String get technicianJobSearch;

  /// No description provided for @technicianAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get technicianAllStatuses;

  /// No description provided for @technicianRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get technicianRefresh;

  /// No description provided for @technicianNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get technicianNextPage;

  /// No description provided for @technicianPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get technicianPreviousPage;

  /// No description provided for @technicianPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {totalPages}'**
  String technicianPageOf(int page, int totalPages);

  /// No description provided for @technicianJobQueue.
  ///
  /// In en, this message translates to:
  /// **'Inspection queue'**
  String get technicianJobQueue;

  /// No description provided for @technicianSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get technicianSyncPending;

  /// No description provided for @technicianOfflineQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. It will sync when online.'**
  String get technicianOfflineQueued;

  /// No description provided for @technicianJobListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No inspections are assigned to you.'**
  String get technicianJobListEmpty;

  /// No description provided for @technicianNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No jobs match your search.'**
  String get technicianNoSearchResults;

  /// No description provided for @technicianVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get technicianVehicle;

  /// No description provided for @technicianCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get technicianCustomer;

  /// No description provided for @technicianScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get technicianScheduledAt;

  /// No description provided for @technicianStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get technicianStartedAt;

  /// No description provided for @technicianAssessmentState.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get technicianAssessmentState;

  /// No description provided for @technicianCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get technicianCategory;

  /// No description provided for @technicianInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get technicianInstructions;

  /// No description provided for @technicianStandardSpec.
  ///
  /// In en, this message translates to:
  /// **'Standard specification'**
  String get technicianStandardSpec;

  /// No description provided for @technicianMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get technicianMeasurement;

  /// No description provided for @technicianMeasurementByPosition.
  ///
  /// In en, this message translates to:
  /// **'Measurement by position'**
  String get technicianMeasurementByPosition;

  /// No description provided for @technicianUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get technicianUnit;

  /// No description provided for @technicianTool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get technicianTool;

  /// No description provided for @technicianSafetyCritical.
  ///
  /// In en, this message translates to:
  /// **'Safety critical'**
  String get technicianSafetyCritical;

  /// No description provided for @technicianMultiPoint.
  ///
  /// In en, this message translates to:
  /// **'Multi-point'**
  String get technicianMultiPoint;

  /// No description provided for @technicianResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get technicianResult;

  /// No description provided for @technicianSelectResult.
  ///
  /// In en, this message translates to:
  /// **'Select a result'**
  String get technicianSelectResult;

  /// No description provided for @technicianSuggestedResult.
  ///
  /// In en, this message translates to:
  /// **'Suggested result'**
  String get technicianSuggestedResult;

  /// No description provided for @technicianScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get technicianScore;

  /// No description provided for @technicianScoreOverride.
  ///
  /// In en, this message translates to:
  /// **'Score override'**
  String get technicianScoreOverride;

  /// No description provided for @technicianScoreHint.
  ///
  /// In en, this message translates to:
  /// **'Allowed range {min}–{max}'**
  String technicianScoreHint(int min, int max);

  /// No description provided for @technicianScoreOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Score must be between {min} and {max}.'**
  String technicianScoreOutOfRange(int min, int max);

  /// No description provided for @technicianIssueDetails.
  ///
  /// In en, this message translates to:
  /// **'Issue details'**
  String get technicianIssueDetails;

  /// No description provided for @technicianIssueDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose from the configured options.'**
  String get technicianIssueDetailsHint;

  /// No description provided for @technicianIssueFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get technicianIssueFieldRequired;

  /// No description provided for @technicianMeasurementRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a measurement for every position.'**
  String get technicianMeasurementRequired;

  /// No description provided for @technicianRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get technicianRequired;

  /// No description provided for @technicianOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get technicianOptional;

  /// No description provided for @technicianSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get technicianSeverity;

  /// No description provided for @technicianNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get technicianNotes;

  /// No description provided for @technicianNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count} characters'**
  String technicianNotesHint(int count);

  /// No description provided for @technicianEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get technicianEvidence;

  /// No description provided for @technicianEvidenceCounts.
  ///
  /// In en, this message translates to:
  /// **'Evidence checklist'**
  String get technicianEvidenceCounts;

  /// No description provided for @technicianEvidencePhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {required} photos'**
  String technicianEvidencePhotoCount(int count, int required);

  /// No description provided for @technicianEvidenceVideoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {required} videos'**
  String technicianEvidenceVideoCount(int count, int required);

  /// No description provided for @technicianEvidenceDocumentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {required} documents'**
  String technicianEvidenceDocumentCount(int count, int required);

  /// No description provided for @technicianEvidenceRequired.
  ///
  /// In en, this message translates to:
  /// **'More evidence is required for this result.'**
  String get technicianEvidenceRequired;

  /// No description provided for @technicianEvidenceSatisfied.
  ///
  /// In en, this message translates to:
  /// **'Evidence requirements met.'**
  String get technicianEvidenceSatisfied;

  /// No description provided for @technicianCapturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get technicianCapturePhoto;

  /// No description provided for @technicianCaptureVideo.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get technicianCaptureVideo;

  /// No description provided for @technicianCaptureDocument.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get technicianCaptureDocument;

  /// No description provided for @technicianPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get technicianPhoto;

  /// No description provided for @technicianVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get technicianVideo;

  /// No description provided for @technicianDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get technicianDocument;

  /// No description provided for @technicianCaptionsEn.
  ///
  /// In en, this message translates to:
  /// **'Caption (English)'**
  String get technicianCaptionsEn;

  /// No description provided for @technicianCaptionsAr.
  ///
  /// In en, this message translates to:
  /// **'Caption (Arabic)'**
  String get technicianCaptionsAr;

  /// No description provided for @technicianCapturePoster.
  ///
  /// In en, this message translates to:
  /// **'Capture poster frame'**
  String get technicianCapturePoster;

  /// No description provided for @technicianCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get technicianCapture;

  /// No description provided for @technicianSaveEvidence.
  ///
  /// In en, this message translates to:
  /// **'Save evidence'**
  String get technicianSaveEvidence;

  /// No description provided for @technicianEvidenceUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {type}...'**
  String technicianEvidenceUploading(String type);

  /// No description provided for @technicianUploadProgress.
  ///
  /// In en, this message translates to:
  /// **'Upload progress'**
  String get technicianUploadProgress;

  /// No description provided for @technicianEvidenceFailed.
  ///
  /// In en, this message translates to:
  /// **'Evidence upload failed.'**
  String get technicianEvidenceFailed;

  /// No description provided for @technicianRetryUpload.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get technicianRetryUpload;

  /// No description provided for @technicianDeleteEvidence.
  ///
  /// In en, this message translates to:
  /// **'Delete evidence'**
  String get technicianDeleteEvidence;

  /// No description provided for @technicianVideoTooLong.
  ///
  /// In en, this message translates to:
  /// **'Video must be 30 seconds or less.'**
  String get technicianVideoTooLong;

  /// No description provided for @technicianVideoTooShort.
  ///
  /// In en, this message translates to:
  /// **'Video must be at least 15 seconds.'**
  String get technicianVideoTooShort;

  /// No description provided for @technicianFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is too large.'**
  String get technicianFileTooLarge;

  /// No description provided for @technicianChooseDocument.
  ///
  /// In en, this message translates to:
  /// **'Choose a document'**
  String get technicianChooseDocument;

  /// No description provided for @technicianAssessmentProgress.
  ///
  /// In en, this message translates to:
  /// **'Assessment progress'**
  String get technicianAssessmentProgress;

  /// No description provided for @technicianPinnedTemplate.
  ///
  /// In en, this message translates to:
  /// **'Pinned template version'**
  String get technicianPinnedTemplate;

  /// No description provided for @technicianReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get technicianReview;

  /// No description provided for @technicianDraftScore.
  ///
  /// In en, this message translates to:
  /// **'Draft score'**
  String get technicianDraftScore;

  /// No description provided for @technicianGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get technicianGrade;

  /// No description provided for @technicianSafetyCap.
  ///
  /// In en, this message translates to:
  /// **'Safety cap'**
  String get technicianSafetyCap;

  /// No description provided for @technicianItemsAssessed.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} items assessed'**
  String technicianItemsAssessed(int done, int total);

  /// No description provided for @technicianBlockers.
  ///
  /// In en, this message translates to:
  /// **'Blockers'**
  String get technicianBlockers;

  /// No description provided for @technicianWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get technicianWarnings;

  /// No description provided for @technicianWarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get technicianWarningsTitle;

  /// No description provided for @technicianConflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get technicianConflicts;

  /// No description provided for @technicianSyncConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync conflict'**
  String get technicianSyncConflictTitle;

  /// No description provided for @technicianConflictExists.
  ///
  /// In en, this message translates to:
  /// **'Resolve sync conflicts before completing.'**
  String get technicianConflictExists;

  /// No description provided for @technicianServerPayload.
  ///
  /// In en, this message translates to:
  /// **'Server payload'**
  String get technicianServerPayload;

  /// No description provided for @technicianClientPayload.
  ///
  /// In en, this message translates to:
  /// **'Client payload'**
  String get technicianClientPayload;

  /// No description provided for @technicianReloadServer.
  ///
  /// In en, this message translates to:
  /// **'Server wins — reload'**
  String get technicianReloadServer;

  /// No description provided for @technicianConflictReloaded.
  ///
  /// In en, this message translates to:
  /// **'Server state reloaded. Revalidate the affected items.'**
  String get technicianConflictReloaded;

  /// No description provided for @technicianNoConflicts.
  ///
  /// In en, this message translates to:
  /// **'No sync conflicts.'**
  String get technicianNoConflicts;

  /// No description provided for @technicianSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection summary'**
  String get technicianSummaryTitle;

  /// No description provided for @technicianOpenSummary.
  ///
  /// In en, this message translates to:
  /// **'Open summary'**
  String get technicianOpenSummary;

  /// No description provided for @technicianComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get technicianComplete;

  /// No description provided for @technicianCompleteInspection.
  ///
  /// In en, this message translates to:
  /// **'Complete inspection'**
  String get technicianCompleteInspection;

  /// No description provided for @technicianSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get technicianSignature;

  /// No description provided for @technicianSignatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer signature'**
  String get technicianSignatureTitle;

  /// No description provided for @technicianSignatureHint.
  ///
  /// In en, this message translates to:
  /// **'Sign inside the box.'**
  String get technicianSignatureHint;

  /// No description provided for @technicianClearSignature.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get technicianClearSignature;

  /// No description provided for @technicianSignerName.
  ///
  /// In en, this message translates to:
  /// **'Signer name'**
  String get technicianSignerName;

  /// No description provided for @technicianSignatureRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a signature and signer name.'**
  String get technicianSignatureRequired;

  /// No description provided for @technicianSignatureSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signature saved.'**
  String get technicianSignatureSuccess;

  /// No description provided for @technicianCompletedPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Inspection completed and sent for review.'**
  String get technicianCompletedPendingReview;

  /// No description provided for @technicianPendingReviewStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get technicianPendingReviewStatus;

  /// No description provided for @technicianJobCompleted.
  ///
  /// In en, this message translates to:
  /// **'Inspection completed'**
  String get technicianJobCompleted;

  /// No description provided for @technicianBackToJobs.
  ///
  /// In en, this message translates to:
  /// **'Back to jobs'**
  String get technicianBackToJobs;

  /// No description provided for @technicianSaveItem.
  ///
  /// In en, this message translates to:
  /// **'Save item'**
  String get technicianSaveItem;

  /// No description provided for @technicianSaveAssessment.
  ///
  /// In en, this message translates to:
  /// **'Save assessment'**
  String get technicianSaveAssessment;

  /// No description provided for @technicianItemSaved.
  ///
  /// In en, this message translates to:
  /// **'Item saved'**
  String get technicianItemSaved;

  /// No description provided for @technicianAssessmentSaved.
  ///
  /// In en, this message translates to:
  /// **'Assessment saved'**
  String get technicianAssessmentSaved;

  /// No description provided for @technicianNetworkRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Your work was saved on this phone and will sync automatically.'**
  String get technicianNetworkRetry;

  /// No description provided for @technicianSyncReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay queued changes'**
  String get technicianSyncReplay;

  /// No description provided for @technicianSyncApplied.
  ///
  /// In en, this message translates to:
  /// **'{count} changes synced.'**
  String technicianSyncApplied(int count);

  /// No description provided for @technicianSyncConflictsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} conflicts'**
  String technicianSyncConflictsCount(int count);

  /// No description provided for @technicianSyncNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting to sync.'**
  String get technicianSyncNothing;

  /// No description provided for @technicianNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items in this category.'**
  String get technicianNoItems;

  /// No description provided for @technicianNoCategories.
  ///
  /// In en, this message translates to:
  /// **'This checklist has no categories.'**
  String get technicianNoCategories;

  /// No description provided for @technicianNoIssues.
  ///
  /// In en, this message translates to:
  /// **'No issues.'**
  String get technicianNoIssues;

  /// No description provided for @platformSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search platform assets, specs, workshop nodes...'**
  String get platformSearchHint;

  /// No description provided for @platformSearchHintCompact.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get platformSearchHintCompact;

  /// No description provided for @platformNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get platformNotifications;

  /// No description provided for @platformNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get platformNotificationsTitle;

  /// No description provided for @platformNotificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get platformNotificationsEmpty;

  /// No description provided for @platformNotificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up. New platform alerts will appear here.'**
  String get platformNotificationsEmptyBody;

  /// No description provided for @platformHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get platformHelp;

  /// No description provided for @platformHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get platformHelpTitle;

  /// No description provided for @platformHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Contact platform support or read the admin guide.'**
  String get platformHelpBody;

  /// No description provided for @platformHelpContact.
  ///
  /// In en, this message translates to:
  /// **'support@truereport.test'**
  String get platformHelpContact;

  /// No description provided for @platformHelpDocs.
  ///
  /// In en, this message translates to:
  /// **'Open admin guide'**
  String get platformHelpDocs;

  /// No description provided for @platformProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get platformProfile;

  /// No description provided for @platformAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get platformAccount;

  /// No description provided for @platformLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get platformLanguage;

  /// No description provided for @platformSwitchToArabic.
  ///
  /// In en, this message translates to:
  /// **'Switch to Arabic'**
  String get platformSwitchToArabic;

  /// No description provided for @platformSwitchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Switch to English'**
  String get platformSwitchToEnglish;

  /// No description provided for @platformHierarchyRoot.
  ///
  /// In en, this message translates to:
  /// **'HIERARCHY ROOT'**
  String get platformHierarchyRoot;

  /// No description provided for @platformActiveWorkshops.
  ///
  /// In en, this message translates to:
  /// **'Active Workshops'**
  String get platformActiveWorkshops;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardKpis.
  ///
  /// In en, this message translates to:
  /// **'Key metrics'**
  String get dashboardKpis;

  /// No description provided for @dashTotalWorkshops.
  ///
  /// In en, this message translates to:
  /// **'Total workshops'**
  String get dashTotalWorkshops;

  /// No description provided for @dashActiveWorkshops.
  ///
  /// In en, this message translates to:
  /// **'Active workshops'**
  String get dashActiveWorkshops;

  /// No description provided for @dashTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get dashTechnicians;

  /// No description provided for @dashActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'Active jobs'**
  String get dashActiveJobs;

  /// No description provided for @dashPendingReviews.
  ///
  /// In en, this message translates to:
  /// **'Pending reviews'**
  String get dashPendingReviews;

  /// No description provided for @dashPublishedReports.
  ///
  /// In en, this message translates to:
  /// **'Published reports'**
  String get dashPublishedReports;

  /// No description provided for @dashChecklistHealth.
  ///
  /// In en, this message translates to:
  /// **'Checklist health'**
  String get dashChecklistHealth;

  /// No description provided for @dashLanguagesLive.
  ///
  /// In en, this message translates to:
  /// **'Languages live'**
  String get dashLanguagesLive;

  /// No description provided for @dashJobsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Jobs by status'**
  String get dashJobsByStatus;

  /// No description provided for @dashReportsByMonth.
  ///
  /// In en, this message translates to:
  /// **'Reports by month'**
  String get dashReportsByMonth;

  /// No description provided for @dashRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashRecentActivity;

  /// No description provided for @dashAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get dashAlerts;

  /// No description provided for @dashQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashQuickActions;

  /// No description provided for @dashViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashViewAll;

  /// No description provided for @dashEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data yet — add your first workshop to get started.'**
  String get dashEmpty;

  /// No description provided for @dashNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No alerts — everything looks healthy.'**
  String get dashNoAlerts;

  /// No description provided for @dashTranslationIncomplete.
  ///
  /// In en, this message translates to:
  /// **'{language} translation incomplete'**
  String dashTranslationIncomplete(String language);

  /// No description provided for @wsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage workshops, staff, and their templates'**
  String get wsSubtitle;

  /// No description provided for @wsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add workshop'**
  String get wsAdd;

  /// No description provided for @wsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search workshops by name, branch, or status'**
  String get wsSearchHint;

  /// No description provided for @wsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit workshop'**
  String get wsEdit;

  /// No description provided for @wsDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate workshop'**
  String get wsDeactivate;

  /// No description provided for @wsReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate workshop'**
  String get wsReactivate;

  /// No description provided for @wsDeactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate this workshop? Staff lose access until it is reactivated.'**
  String get wsDeactivateConfirm;

  /// No description provided for @wsName.
  ///
  /// In en, this message translates to:
  /// **'Workshop name'**
  String get wsName;

  /// No description provided for @wsBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get wsBranch;

  /// No description provided for @wsContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email'**
  String get wsContactEmail;

  /// No description provided for @wsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get wsOverview;

  /// No description provided for @wsStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get wsStaff;

  /// No description provided for @wsWorkshopTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get wsWorkshopTemplates;

  /// No description provided for @wsActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get wsActivity;

  /// No description provided for @wsCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get wsCapacity;

  /// No description provided for @wsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get wsContact;

  /// No description provided for @wsCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get wsCreatedOn;

  /// No description provided for @wsAddStaff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get wsAddStaff;

  /// No description provided for @wsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workshops yet'**
  String get wsEmpty;

  /// No description provided for @wsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first workshop to start onboarding staff.'**
  String get wsEmptyBody;

  /// No description provided for @wsResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} workshops'**
  String wsResultCount(int count);

  /// No description provided for @chkItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist items'**
  String get chkItemsTitle;

  /// No description provided for @chkCategoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Category filter'**
  String get chkCategoryFilter;

  /// No description provided for @chkAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get chkAllCategories;

  /// No description provided for @chkSearchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get chkSearchCategories;

  /// No description provided for @chkEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get chkEvidence;

  /// No description provided for @chkUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get chkUpdated;

  /// No description provided for @chkResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String chkResultCount(int count);

  /// No description provided for @stepBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get stepBasics;

  /// No description provided for @stepContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get stepContent;

  /// No description provided for @stepIssueOptions.
  ///
  /// In en, this message translates to:
  /// **'Issue options'**
  String get stepIssueOptions;

  /// No description provided for @stepEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get stepEvidence;

  /// No description provided for @stepMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get stepMeasurement;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Review & publish'**
  String get stepReview;

  /// No description provided for @stepBasicsHelp.
  ///
  /// In en, this message translates to:
  /// **'Define the item identity and behavior.'**
  String get stepBasicsHelp;

  /// No description provided for @stepContentHelp.
  ///
  /// In en, this message translates to:
  /// **'Write instructions for every live language.'**
  String get stepContentHelp;

  /// No description provided for @stepIssueHelp.
  ///
  /// In en, this message translates to:
  /// **'Define the fields technicians fill when they find an issue.'**
  String get stepIssueHelp;

  /// No description provided for @stepEvidenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Set the minimum photo, video, and note evidence.'**
  String get stepEvidenceHelp;

  /// No description provided for @stepMeasureHelp.
  ///
  /// In en, this message translates to:
  /// **'Map measurement ranges to results. No scores.'**
  String get stepMeasureHelp;

  /// No description provided for @stepReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Review everything, save a draft, or publish.'**
  String get stepReviewHelp;

  /// No description provided for @stepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepCounter(int current, int total);

  /// No description provided for @itemAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get itemAdvanced;

  /// No description provided for @itemSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get itemSaveDraft;

  /// No description provided for @tmplCreate.
  ///
  /// In en, this message translates to:
  /// **'Create template'**
  String get tmplCreate;

  /// No description provided for @tmplBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'Template builder'**
  String get tmplBuilderTitle;

  /// No description provided for @tmplStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tmplStepDetails;

  /// No description provided for @tmplStepCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get tmplStepCategories;

  /// No description provided for @tmplStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get tmplStepReview;

  /// No description provided for @tmplAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get tmplAddCategory;

  /// No description provided for @tmplAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get tmplAddItem;

  /// No description provided for @tmplSearchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get tmplSearchCategories;

  /// No description provided for @tmplSearchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get tmplSearchItems;

  /// No description provided for @tmplEmptyCategory.
  ///
  /// In en, this message translates to:
  /// **'No items in this category yet'**
  String get tmplEmptyCategory;

  /// No description provided for @tmplDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get tmplDuplicate;

  /// No description provided for @tmplProgressCategories.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String tmplProgressCategories(int count);

  /// No description provided for @tmplProgressItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String tmplProgressItems(int count);

  /// No description provided for @optHelper.
  ///
  /// In en, this message translates to:
  /// **'Option sets define the choices technicians pick when reporting an issue. Values are shared across items.'**
  String get optHelper;

  /// No description provided for @optSearchSets.
  ///
  /// In en, this message translates to:
  /// **'Search option sets'**
  String get optSearchSets;

  /// No description provided for @optSearchValues.
  ///
  /// In en, this message translates to:
  /// **'Search values'**
  String get optSearchValues;

  /// No description provided for @optAddValue.
  ///
  /// In en, this message translates to:
  /// **'Add value'**
  String get optAddValue;

  /// No description provided for @optValues.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get optValues;

  /// No description provided for @optInlineHint.
  ///
  /// In en, this message translates to:
  /// **'Edit inline; changes save immediately.'**
  String get optInlineHint;

  /// No description provided for @optUsedBy.
  ///
  /// In en, this message translates to:
  /// **'Used by'**
  String get optUsedBy;

  /// No description provided for @langStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get langStatusDraft;

  /// No description provided for @langStatusTranslating.
  ///
  /// In en, this message translates to:
  /// **'Translating'**
  String get langStatusTranslating;

  /// No description provided for @langStatusReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get langStatusReview;

  /// No description provided for @langStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get langStatusLive;

  /// No description provided for @langStatusRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get langStatusRetired;

  /// No description provided for @langCompleteTranslations.
  ///
  /// In en, this message translates to:
  /// **'Complete translations'**
  String get langCompleteTranslations;

  /// No description provided for @langPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish language'**
  String get langPublish;

  /// No description provided for @langPublishBlocked.
  ///
  /// In en, this message translates to:
  /// **'Complete all required translations to publish.'**
  String get langPublishBlocked;

  /// No description provided for @queueMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get queueMissing;

  /// No description provided for @queueDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get queueDraft;

  /// No description provided for @queueReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get queueReviewed;

  /// No description provided for @queueApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get queueApproved;

  /// No description provided for @queueTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get queueTotal;

  /// No description provided for @queueEntityType.
  ///
  /// In en, this message translates to:
  /// **'Entity type'**
  String get queueEntityType;

  /// No description provided for @queueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search translations'**
  String get queueSearchHint;

  /// No description provided for @queueMissingOnly.
  ///
  /// In en, this message translates to:
  /// **'Missing only'**
  String get queueMissingOnly;

  /// No description provided for @queueEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit translation'**
  String get queueEditTitle;

  /// No description provided for @queueSaveAll.
  ///
  /// In en, this message translates to:
  /// **'Save all'**
  String get queueSaveAll;

  /// No description provided for @queueApproveSelected.
  ///
  /// In en, this message translates to:
  /// **'Approve selected'**
  String get queueApproveSelected;

  /// No description provided for @queueDefaultText.
  ///
  /// In en, this message translates to:
  /// **'Default text'**
  String get queueDefaultText;

  /// No description provided for @queueTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get queueTranslation;

  /// No description provided for @queuePublishLanguage.
  ///
  /// In en, this message translates to:
  /// **'Publish language'**
  String get queuePublishLanguage;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'All translations complete'**
  String get queueEmpty;

  /// No description provided for @queueEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is missing for this language.'**
  String get queueEmptyBody;

  /// No description provided for @queueExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get queueExport;

  /// No description provided for @reportLabels.
  ///
  /// In en, this message translates to:
  /// **'Report labels'**
  String get reportLabels;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
