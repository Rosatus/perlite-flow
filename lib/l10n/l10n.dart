import 'package:flutter/widgets.dart';

import '../services/perlite_client.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension PerliteErrorText on AppLocalizations {
  /// Converts service and unexpected errors into user-facing text.
  String errorMessage(Object error) {
    if (error is! PerliteException) return errorRequestFailed(error.toString());
    return switch (error.kind) {
      PerliteErrorKind.unauthorized => errorUnauthorized,
      PerliteErrorKind.forbidden => errorForbidden,
      PerliteErrorKind.notFound => errorNotFound,
      PerliteErrorKind.dnsFailed => errorDnsFailed,
      PerliteErrorKind.tlsFailed => errorTlsFailed,
      PerliteErrorKind.connectionRefused => errorConnectionRefused,
      PerliteErrorKind.networkUnreachable => errorNetworkUnreachable,
      PerliteErrorKind.connectionFailed => errorConnectionFailed(error.detail),
      PerliteErrorKind.httpStatus => errorHttpStatus(error.detail),
      PerliteErrorKind.requestFailed => errorRequestFailed(error.detail),
      PerliteErrorKind.invalidUrl => errorInvalidUrl,
    };
  }
}
