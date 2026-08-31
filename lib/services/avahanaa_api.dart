/// The app's client for the avahanaa.com backend.
///
/// Most of what this app does reaches Firebase directly through
/// [FirestoreService]. Three things cannot, because they decide something the
/// client is not allowed to decide:
///
/// - crediting the wallet after a rewarded ad (a client that could grant itself
///   credits would make the meter decorative),
/// - activating a subscription (the Play purchase token has to be verified
///   against Google's servers, with our credentials, not the phone's),
/// - reading back what the scanner attached to an alert.
///
/// So they go over HTTPS to the same host the QR sticker points at, with the
/// caller's Firebase ID token in the Authorization header. The endpoints live
/// in the `Avahanaa-Web` repo — see `docs/web_backend_sync.md` for why the
/// backend is not in this one, and `docs/backend_contract.md` for the shape of
/// everything crossing this boundary.
///
/// The host is the same `--dart-define` the QR builder uses, so a staging build
/// points the app and its stickers at the same place without a second flag.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../utils/qr_payload_builder.dart';

/// What a call to the backend came back with.
///
/// Deliberately not an exception-per-failure design. Every one of these calls
/// happens behind a button the user pressed, and every failure mode ends the
/// same way — a sentence in a snackbar — so the caller wants a value it can
/// switch on, not a stack of catch blocks.
class ApiResult<T> {
  const ApiResult.ok(this.data) : error = null, statusCode = 200;
  const ApiResult.failure(this.error, {this.statusCode = 0}) : data = null;

  final T? data;
  final String? error;
  final int statusCode;

  bool get isOk => error == null;

  /// True when trying again might work: a timeout, a dropped connection, a 5xx.
  /// A 400 means the request was wrong and repeating it will be wrong again.
  bool get isRetryable => !isOk && (statusCode == 0 || statusCode >= 500);
}

class AvahanaaApi {
  AvahanaaApi._();

  static final AvahanaaApi instance = AvahanaaApi._();

  /// Short by design. Every one of these calls has a person waiting on it, and
  /// a spinner that runs for thirty seconds is indistinguishable from a hang.
  static const Duration _timeout = Duration(seconds: 12);

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  /// Base origin, e.g. `https://avahanaa.com`.
  ///
  /// Shares [QrPayloadBuilder.redirectHost] so a build pointed at staging
  /// stickers is also pointed at staging APIs. Two flags that must agree is a
  /// bug waiting to be filed.
  static String get origin => 'https://${QrPayloadBuilder.redirectHost}';

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$origin$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  /// A fresh Firebase ID token, or null when nobody is signed in.
  ///
  /// Not force-refreshed: the SDK already rotates it an hour before expiry, and
  /// forcing a refresh adds a network round trip in front of a call that
  /// already has one.
  Future<String?> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken();
    } catch (e) {
      log('Could not mint an ID token: $e');
      return null;
    }
  }

  Future<ApiResult<Map<String, dynamic>>> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    String? token;
    if (authenticated) {
      token = await _idToken();
      if (token == null) {
        return const ApiResult.failure('You need to be signed in.');
      }
    }

    try {
      final request = await _client.openUrl(method, uri).timeout(_timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response = await request.close().timeout(_timeout);
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);

      Map<String, dynamic> decoded = const {};
      if (text.trim().isNotEmpty) {
        final parsed = jsonDecode(text);
        if (parsed is Map<String, dynamic>) decoded = parsed;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.ok(decoded);
      }

      final error = decoded['error'];
      final message = error is Map && error['message'] is String
          ? error['message'] as String
          : 'That did not go through. Please try again.';
      return ApiResult.failure(message, statusCode: response.statusCode);
    } on TimeoutException {
      return const ApiResult.failure(
        'The network is taking too long. Try again in a moment.',
      );
    } on SocketException {
      return const ApiResult.failure('No internet connection.');
    } catch (e, stack) {
      log('API call failed: $uri', error: e, stackTrace: stack);
      return const ApiResult.failure(
        'That did not go through. Please try again.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Wallet
  // -------------------------------------------------------------------------

  /// Claims the credit for a rewarded ad the user has just finished watching.
  ///
  /// This is the *belt* — the braces are AdMob's server-side verification
  /// callback, which reaches the backend directly from Google with a signed
  /// payload and is what actually moves the balance. This call only tells the
  /// backend to look now rather than on the next poll, so the counter on screen
  /// ticks up while the user is still looking at it.
  ///
  /// [rewardToken] is the SSV custom-data nonce the app minted before showing
  /// the ad; it is how the backend matches Google's callback to this session.
  /// Returns the balance once the callback has landed, or null while it is
  /// still in flight. Null is not an error — the credit arrives either way, and
  /// the caller's job is simply to wait a moment and ask again.
  Future<ApiResult<int?>> claimAdReward({required String rewardToken}) async {
    final result = await _send(
      'POST',
      _uri('/api/wallet/claim'),
      body: {'rewardToken': rewardToken},
    );
    if (!result.isOk) {
      return ApiResult.failure(result.error!, statusCode: result.statusCode);
    }
    final data = result.data ?? const <String, dynamic>{};
    if (data['settled'] != true) return const ApiResult.ok(null);
    final credits = data['credits'];
    return ApiResult.ok(credits is num ? credits.toInt() : 0);
  }

  /// Hands a Google Play purchase token to the backend for verification.
  ///
  /// The app never decides that somebody is subscribed. It cannot: a rooted
  /// phone can hand this method anything it likes. The backend asks the Play
  /// Developer API whether the token is real, what it bought and when it
  /// expires, and only then writes `plan` and `planExpiresAt`.
  Future<ApiResult<void>> verifySubscription({
    required String productId,
    required String purchaseToken,
  }) async {
    final result = await _send(
      'POST',
      _uri('/api/billing/verify'),
      body: {
        'platform': 'android',
        'productId': productId,
        'purchaseToken': purchaseToken,
      },
    );
    if (!result.isOk) {
      return ApiResult.failure(result.error!, statusCode: result.statusCode);
    }
    return const ApiResult.ok(null);
  }

  // -------------------------------------------------------------------------
  // Self-test
  // -------------------------------------------------------------------------

  /// Fires a real alert at the caller's own phone.
  ///
  /// Walks the whole live path — the same document, the same push, the same
  /// alarm channel, the same full-screen intent — because the thing being
  /// tested is not our code. It is this particular phone: its Do Not Disturb
  /// rules, its battery optimiser, and whatever its manufacturer thinks about
  /// background apps. Xiaomi, Oppo, Vivo and Samsung all ship killers that
  /// silently break FCM delivery and report nothing, and the only detector is
  /// an owner who asked for an alert and can tell you it never came.
  Future<ApiResult<void>> sendTestAlert({String vehicleId = ''}) async {
    final result = await _send(
      'POST',
      _uri('/api/alerts/test'),
      body: {'vehicleId': vehicleId},
    );
    if (!result.isOk) {
      return ApiResult.failure(result.error!, statusCode: result.statusCode);
    }
    return const ApiResult.ok(null);
  }

  void dispose() => _client.close(force: true);
}
