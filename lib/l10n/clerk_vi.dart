import 'package:clerk_flutter/clerk_flutter.dart';

import 'l10n.dart';

/// Vietnamese copy for the installed Clerk native UI.
///
/// This adapter changes labels only; Clerk retains every authentication flow.
class SoundShareClerkLocalizationsVi extends ClerkSdkLocalizations {
  SoundShareClerkLocalizationsVi() : super('vi');

  @override
  String aLengthOfBetweenMINAndMAX(int min, int max) =>
      appCopy.clerkALengthOfBetweenMINAndMAX(min, max);

  @override
  String aLengthOfMINOrGreater(int min) =>
      appCopy.clerkALengthOfMINOrGreater(min);

  @override
  String get aLowercaseLetter => appCopy.clerkALowercaseLetter;

  @override
  String get aNumber => appCopy.clerkANumber;

  @override
  String aSpecialCharacter(String chars) =>
      appCopy.clerkASpecialCharacter(chars);

  @override
  String get abandoned => appCopy.clerkAbandoned;

  @override
  String get acceptTerms => appCopy.clerkAcceptTerms;

  @override
  String get active => appCopy.clerkActive;

  @override
  String get addAccount => appCopy.clerkAddAccount;

  @override
  String get addDomain => appCopy.clerkAddDomain;

  @override
  String get addEmailAddress => appCopy.clerkAddEmailAddress;

  @override
  String get addPasskey => appCopy.clerkAddPasskey;

  @override
  String get addPhoneNumber => appCopy.clerkAddPhoneNumber;

  @override
  String get alreadyHaveAnAccount => appCopy.clerkAlreadyHaveAnAccount;

  @override
  String get anUppercaseLetter => appCopy.clerkAnUppercaseLetter;

  @override
  String get and => appCopy.clerkAnd;

  @override
  String get areYouSure => appCopy.clerkAreYouSure;

  @override
  String authenticationServiceError(String arg) =>
      appCopy.clerkAuthenticationServiceError;

  @override
  String get authenticatorApp => appCopy.clerkAuthenticatorApp;

  @override
  String get automaticInvitation => appCopy.clerkAutomaticInvitation;

  @override
  String get automaticSuggestion => appCopy.clerkAutomaticSuggestion;

  @override
  String get back => appCopy.clerkBack;

  @override
  String get backupCode => appCopy.clerkBackupCode;

  @override
  String get cancel => appCopy.clerkCancel;

  @override
  String get cannotDeleteSelf => appCopy.clerkCannotDeleteSelf;

  @override
  String clickOnTheLinkThatsBeenSentTo(String identifier) =>
      appCopy.clerkClickOnTheLinkThatsBeenSentTo(identifier);

  @override
  String get clickOnTheLinkThatsBeenSentToYou =>
      appCopy.clerkClickOnTheLinkThatsBeenSentToYou;

  @override
  String get complete => appCopy.clerkComplete;

  @override
  String get connectAccount => appCopy.clerkConnectAccount;

  @override
  String get connectedAccounts => appCopy.clerkConnectedAccounts;

  @override
  String get cont => appCopy.clerkCont;

  @override
  String get createOrganization => appCopy.clerkCreateOrganization;

  @override
  String get created => appCopy.clerkCreated;

  @override
  String get developmentMode => appCopy.clerkDevelopmentMode;

  @override
  String get didntReceiveCode => appCopy.clerkDidntReceiveCode;

  @override
  String get domainName => appCopy.clerkDomainName;

  @override
  String get dontHaveAnAccount => appCopy.clerkDontHaveAnAccount;

  @override
  String get edit => appCopy.clerkEdit;

  @override
  String get emailAddress => appCopy.clerkEmailAddress;

  @override
  String get emailAddressConcise => appCopy.clerkEmailAddressConcise;

  @override
  String get emailAddresses => appCopy.clerkEmailAddresses;

  @override
  String get enrollment => appCopy.clerkEnrollment;

  @override
  String get enrollmentMode => appCopy.clerkEnrollmentMode;

  @override
  String get enterOneOfYourBackupCodes =>
      appCopy.clerkEnterOneOfYourBackupCodes;

  @override
  String get enterTheCodeFromYourAuthenticatorApp =>
      appCopy.clerkEnterTheCodeFromYourAuthenticatorApp;

  @override
  String enterTheCodeSentTo(String identifier) =>
      appCopy.clerkEnterTheCodeSentTo(identifier);

  @override
  String get enterTheCodeSentToYou => appCopy.clerkEnterTheCodeSentToYou;

  @override
  String get enterTheCodeSentToYouByEmail =>
      appCopy.clerkEnterTheCodeSentToYouByEmail;

  @override
  String get enterTheCodeSentToYouByTextMessage =>
      appCopy.clerkEnterTheCodeSentToYouByTextMessage;

  @override
  String get enterYourOrganizationDetailsToContinue =>
      appCopy.clerkEnterYourOrganizationDetailsToContinue;

  @override
  String get enterYourPassword => appCopy.clerkEnterYourPassword;

  @override
  String get expired => appCopy.clerkExpired;

  @override
  String externalError(String arg) => appCopy.clerkExternalError;

  @override
  String get failed => appCopy.clerkFailed;

  @override
  String get firstName => appCopy.clerkFirstName;

  @override
  String get forgottenPassword => appCopy.clerkForgottenPassword;

  @override
  String get generalDetails => appCopy.clerkGeneralDetails;

  @override
  String invalidEmailAddress(String address) =>
      appCopy.clerkInvalidEmailAddress(address);

  @override
  String invalidPhoneNumber(String number) =>
      appCopy.clerkInvalidPhoneNumber(number);

  @override
  String get join => appCopy.clerkJoin;

  @override
  // The SDK passes the raw JWT here; never render it in the error UI.
  String jwtPoorlyFormatted(String arg) => appCopy.clerkJwtPoorlyFormatted;

  @override
  String get lastName => appCopy.clerkLastName;

  @override
  String get lastUsed => appCopy.clerkLastUsed;

  @override
  String get leave => appCopy.clerkLeave;

  @override
  String leaveOrg(String organization) => appCopy.clerkLeaveOrg(organization);

  @override
  String get leaveOrganization => appCopy.clerkLeaveOrganization;

  @override
  String get legalAcceptanceRequired => appCopy.clerkLegalAcceptanceRequired;

  @override
  String get loading => appCopy.clerkLoading;

  @override
  String get logo => appCopy.clerkLogo;

  @override
  String get longDateFormat => appCopy.clerkLongDateFormat;

  @override
  String get manualInvitation => appCopy.clerkManualInvitation;

  @override
  String get missingRequirements => appCopy.clerkMissingRequirements;

  @override
  String get myOrganization => appCopy.clerkMyOrganization;

  @override
  String get name => appCopy.clerkName;

  @override
  String get needsFirstFactor => appCopy.clerkNeedsFirstFactor;

  @override
  String get needsIdentifier => appCopy.clerkNeedsIdentifier;

  @override
  String get needsSecondFactor => appCopy.clerkNeedsSecondFactor;

  @override
  String get newPassword => appCopy.clerkNewPassword;

  @override
  String get newPasswordConfirmation => appCopy.clerkNewPasswordConfirmation;

  @override
  String noAssociatedCodeRetrievalMethod(String arg) =>
      appCopy.clerkNoAssociatedCodeRetrievalMethod(arg);

  @override
  String noAssociatedStrategy(String arg) =>
      appCopy.clerkNoAssociatedStrategy(arg);

  @override
  String get noInitialCodeHasBeenSetUpToResend =>
      appCopy.clerkNoInitialCodeHasBeenSetUpToResend;

  @override
  String noSessionFoundForUser(String arg) =>
      appCopy.clerkNoSessionFoundForUser(arg);

  @override
  String get noSessionTokenRetrieved => appCopy.clerkNoSessionTokenRetrieved;

  @override
  String noStageForStatus(String arg) => appCopy.clerkNoStageForStatus(arg);

  @override
  String noSuchFirstFactorStrategy(String arg) =>
      appCopy.clerkNoSuchFirstFactorStrategy(arg);

  @override
  String noSuchSecondFactorStrategy(String arg) =>
      appCopy.clerkNoSuchSecondFactorStrategy(arg);

  @override
  String noUserAttributeForField(String arg) =>
      appCopy.clerkNoUserAttributeForField(arg);

  @override
  String get ok => appCopy.clerkOk;

  @override
  String get optional => appCopy.clerkOptional;

  @override
  String get or => appCopy.clerkOr;

  @override
  String get organizationProfile => appCopy.clerkOrganizationProfile;

  @override
  String get organizations => appCopy.clerkOrganizations;

  @override
  String get passkey => appCopy.clerkPasskey;

  @override
  String get passkeys => appCopy.clerkPasskeys;

  @override
  String get password => appCopy.clerkPassword;

  @override
  String get passwordConfirmation => appCopy.clerkPasswordConfirmation;

  @override
  String get passwordMatchError => appCopy.clerkPasswordMatchError;

  @override
  String get passwordMustBeSupplied => appCopy.clerkPasswordMustBeSupplied;

  @override
  String get passwordRequires => appCopy.clerkPasswordRequires;

  @override
  String get pending => appCopy.clerkPending;

  @override
  String get personalAccount => appCopy.clerkPersonalAccount;

  @override
  String get phoneNumber => appCopy.clerkPhoneNumber;

  @override
  String get phoneNumberConcise => appCopy.clerkPhoneNumberConcise;

  @override
  String get phoneNumbers => appCopy.clerkPhoneNumbers;

  @override
  String get pleaseAddRequiredInformation =>
      appCopy.clerkPleaseAddRequiredInformation;

  @override
  String get pleaseChooseAnAccountToConnect =>
      appCopy.clerkPleaseChooseAnAccountToConnect;

  @override
  String get pleaseEnterYourIdentifier =>
      appCopy.clerkPleaseEnterYourIdentifier;

  @override
  String get primary => appCopy.clerkPrimary;

  @override
  String get privacyPolicy => appCopy.clerkPrivacyPolicy;

  @override
  String get profile => appCopy.clerkProfile;

  @override
  String get profileDetails => appCopy.clerkProfileDetails;

  @override
  String get recommendSize => appCopy.clerkRecommendSize;

  @override
  String get requiredField => appCopy.clerkRequiredField;

  @override
  String get requiredFieldsAreMissing => appCopy.clerkRequiredFieldsAreMissing;

  @override
  String get resend => appCopy.clerkResend;

  @override
  String get resetFailed => appCopy.clerkResetFailed;

  @override
  String get resetPassword => appCopy.clerkResetPassword;

  @override
  String get selectAccount => appCopy.clerkSelectAccount;

  @override
  String get sendMeTheCode => appCopy.clerkSendMeTheCode;

  @override
  String serverErrorResponse(String arg) =>
      appCopy.clerkServerErrorResponse(arg);

  @override
  String get setUpYourOrganization => appCopy.clerkSetUpYourOrganization;

  @override
  String get signIn => appCopy.clerkSignIn;

  @override
  String get signInByCodeSentToYourEmail =>
      appCopy.clerkSignInByCodeSentToYourEmail;

  @override
  String signInByEmailCode(String arg) => appCopy.clerkSignInByEmailCode(arg);

  @override
  String signInByEmailLink(String arg) => appCopy.clerkSignInByEmailLink(arg);

  @override
  String get signInByEnteringOneOfYourBackupCodes =>
      appCopy.clerkSignInByEnteringOneOfYourBackupCodes;

  @override
  String get signInByLinkSentToYourEmail =>
      appCopy.clerkSignInByLinkSentToYourEmail;

  @override
  String signInBySMSCode(String arg) => appCopy.clerkSignInBySMSCode(arg);

  @override
  String get signInBySMSCodeToYourPhone =>
      appCopy.clerkSignInBySMSCodeToYourPhone;

  @override
  String signInTo(String name) => appCopy.clerkSignInTo(name);

  @override
  String get signInUsingEnterpriseSSO => appCopy.clerkSignInUsingEnterpriseSSO;

  @override
  String get signInUsingYourAuthenticatorApp =>
      appCopy.clerkSignInUsingYourAuthenticatorApp;

  @override
  String get signInWithOneOfYourBackupCodes =>
      appCopy.clerkSignInWithOneOfYourBackupCodes;

  @override
  String get signOut => appCopy.clerkSignOut;

  @override
  String signOutIdentifier(String identifier) =>
      appCopy.clerkSignOutIdentifier(identifier);

  @override
  String get signOutOfAllAccounts => appCopy.clerkSignOutOfAllAccounts;

  @override
  String get signUp => appCopy.clerkSignUp;

  @override
  String signUpTo(String name) => appCopy.clerkSignUpTo(name);

  @override
  String get slug => appCopy.clerkSlug;

  @override
  String get slugUrl => appCopy.clerkSlugUrl;

  @override
  String get switchTo => appCopy.clerkSwitchTo;

  @override
  String get termsOfService => appCopy.clerkTermsOfService;

  @override
  String get tooManyRetries => appCopy.clerkTooManyRetries;

  @override
  String get transferable => appCopy.clerkTransferable;

  @override
  String get twoStepVerification => appCopy.clerkTwoStepVerification;

  @override
  String typeTypeInvalid(String type) => appCopy.clerkTypeTypeInvalid(type);

  @override
  String unknownError(String arg) => appCopy.clerkUnknownError;

  @override
  String unsupportedPasswordResetStrategy(String arg) =>
      appCopy.clerkUnsupportedPasswordResetStrategy(arg);

  @override
  String get unverified => appCopy.clerkUnverified;

  @override
  String get usePasskeyInstead => appCopy.clerkUsePasskeyInstead;

  @override
  String get username => appCopy.clerkUsername;

  @override
  String get verificationEmailAddress => appCopy.clerkVerificationEmailAddress;

  @override
  String get verificationPhoneNumber => appCopy.clerkVerificationPhoneNumber;

  @override
  String get verified => appCopy.clerkVerified;

  @override
  String get verifiedDomains => appCopy.clerkVerifiedDomains;

  @override
  String get verifyThisDevice => appCopy.clerkVerifyThisDevice;

  @override
  String get verifyYourEmailAddress => appCopy.clerkVerifyYourEmailAddress;

  @override
  String get verifyYourPhoneNumber => appCopy.clerkVerifyYourPhoneNumber;

  @override
  String get viaAutomaticInvitation => appCopy.clerkViaAutomaticInvitation;

  @override
  String get viaAutomaticSuggestion => appCopy.clerkViaAutomaticSuggestion;

  @override
  String get viaManualInvitation => appCopy.clerkViaManualInvitation;

  @override
  String get web3Wallet => appCopy.clerkWeb3Wallet;

  @override
  String get welcomeBackPleaseSignInToContinue =>
      appCopy.clerkWelcomeBackPleaseSignInToContinue;

  @override
  String get welcomePleaseFillInTheDetailsToGetStarted =>
      appCopy.clerkWelcomePleaseFillInTheDetailsToGetStarted;
}
