import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_vi.dart';

export 'generated/app_localizations.dart';

// Non-widget errors and isolated screen previews use the same Vietnamese ARB.
final AppLocalizations appCopy = AppLocalizationsVi();

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this) ?? appCopy;
}
