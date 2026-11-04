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
  /// **'Loading…'**
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
  /// **'English label'**
  String get labelEn;

  /// No description provided for @labelAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic label'**
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
  /// **'Minimum photos'**
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
  /// **'Create new draft'**
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
  /// **'Templates'**
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
  /// **'Safety-critical'**
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
