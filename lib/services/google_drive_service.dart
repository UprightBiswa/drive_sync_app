import 'dart:io';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Injects fresh auth headers for every request using GoogleSignIn 7.x
class _AuthHeadersClient extends http.BaseClient {
  final http.Client _inner;
  final Future<Map<String, String>?> Function() _getHeaders;
  _AuthHeadersClient(this._getHeaders, [http.Client? inner])
      : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await _getHeaders();
    if (headers == null) {
      throw Exception('Authorization headers unavailable');
    }
    request.headers.addAll(headers);
    return _inner.send(request);
  }
}

class GoogleDriveService {
  final Rx<GoogleSignInAccount?> currentUser = Rx<GoogleSignInAccount?>(null);

  GoogleDriveService() {
    // Initialize once, then listen to auth events
    GoogleSignIn.instance
        .initialize(
          // For Android/iOS with config files, leave nulls.
          clientId: null,
          serverClientId: null,
        )
        .then((_) {
      GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            currentUser.value = event.user;
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            currentUser.value = null;
          }
        },
        onError: (err) => print('Auth stream error: $err'),
      );

      // Attempt silent/lightweight auth
      GoogleSignIn.instance.attemptLightweightAuthentication();
    });
  }

  Future<void> signIn() async {
    try {
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        // Interactive sign-in (button press context)
        final user = await GoogleSignIn.instance.authenticate();
        // Request Drive scope right away so uploads work
        await user.authorizationClient.authorizeScopes(
          const [drive.DriveApi.driveFileScope],
        );
      } else {
        Get.snackbar(
          'Sign-In Error',
          'This platform does not support authenticate() directly.',
        );
      }
    } on GoogleSignInException catch (e) {
      Get.snackbar('Sign-In Failed', 'GoogleSignInException ${e.code}: ${e.description}');
    } catch (e) {
      Get.snackbar('Sign-In Failed', 'Could not sign in: $e');
      print('signIn error: $e');
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.disconnect();
  }

  Future<bool> uploadFile(File file) async {
    final user = currentUser.value;
    if (user == null) {
      print('User not signed in.');
      return false;
    }

    try {
      // Provide headers on-demand (refreshes token when needed)
      final client = _AuthHeadersClient(() async {
        // Try to get headers silently; if not present, prompt is false here.
        // You can set promptIfNecessary: true if this runs in foreground UI.
        return user.authorizationClient.authorizationHeaders(
          const [drive.DriveApi.driveFileScope],
          // In background tasks, keep this false; in UI flows you can set true.
          promptIfNecessary: false,
        );
      });

      final driveApi = drive.DriveApi(client);

      final driveFile = drive.File()..name = path.basename(file.path);
      final media = drive.Media(file.openRead(), await file.length());

      final created = await driveApi.files.create(driveFile, uploadMedia: media);
      print('Uploaded: ${created.name} (${created.id})');
      return true;
    } on drive.DetailedApiRequestError catch (e) {
      // Common 401/403 if auth missing/expired
      print('Drive API error ${e.status}: ${e.message}');
      return false;
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }
}
