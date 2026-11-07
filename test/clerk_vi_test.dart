import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/l10n/clerk_vi.dart';

void main() {
  test('Native Clerk keeps Vietnamese when the device uses another locale', () {
    final copy = SoundShareClerkLocalizationsVi();
    // Config resolution is local; no SDK initialization or provider request.
    final config = ClerkAuthConfig(
      publishableKey: 'pk_test_placeholder',
      localizations: {'vi': copy},
      fallbackLocalization: copy,
    );

    expect(config.localizationsForLocale(const Locale('vi', 'VN')), same(copy));
    expect(config.localizationsForLocale(const Locale('en', 'US')), same(copy));
    expect(config.localizationsForLocale(const Locale('ja')), same(copy));
    expect(config.localesLookup().first, 'vi');
    expect(copy.signIn, 'Đăng nhập');
    expect(copy.signUp, 'Đăng ký');
    expect(copy.forgottenPassword, 'Bạn quên mật khẩu?');
  });

  test('Native verification copy preserves recipient and account names', () {
    final copy = SoundShareClerkLocalizationsVi();
    const recipient = 'listener+sample@example.invalid';
    const name = 'Giai điệu {riêng} & SoundShare';

    expect(copy.enterTheCodeSentTo(recipient), 'Nhập mã đã gửi đến $recipient');
    expect(copy.signInByEmailLink(recipient), endsWith(recipient));
    expect(
      copy.signInBySMSCode('+84 000 000 000'),
      endsWith('+84 000 000 000'),
    );
    expect(copy.signInTo(name), 'Đăng nhập vào $name');
    expect(copy.signUpTo(name), 'Đăng ký vào $name');
    expect(copy.aLengthOfBetweenMINAndMAX(8, 64), 'độ dài từ 8 đến 64 ký tự');
    expect(copy.aSpecialCharacter('!@#'), contains('!@#'));
  });

  test('Malformed native session errors never display the raw credential', () {
    final copy = SoundShareClerkLocalizationsVi();
    const malformedCredential =
        'fixture-header.fixture-payload.fixture-signature';

    expect(
      copy.jwtPoorlyFormatted(malformedCredential),
      isNot(contains(malformedCredential)),
    );
    expect(
      copy.jwtPoorlyFormatted(malformedCredential),
      contains('đăng nhập lại'),
    );
  });

  test('Native service failures hide raw provider details', () {
    final copy = SoundShareClerkLocalizationsVi();
    const rawDetails = 'private-provider-details-in-English';

    for (final message in [
      copy.authenticationServiceError(rawDetails),
      copy.externalError(rawDetails),
      copy.unknownError(rawDetails),
    ]) {
      expect(message, isNot(contains(rawDetails)));
      expect(message, contains('thử lại'));
    }
  });
}
