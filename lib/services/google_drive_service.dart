// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;

// class GoogleDriveService {
//   final Rx<GoogleSignInAccount?> currentUser = Rx<GoogleSignInAccount?>(null);

//   final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

//   static const List<String> driveScopes = <String>[drive.DriveApi.driveFileScope];

//   GoogleDriveService() {
//     _googleSignIn
//         .initialize(
//           clientId:
//               '868153586645-qrqrm6edsnfpj90jj4k729hrr0nnvra9.apps.googleusercontent.com',
//           serverClientId:
//               '868153586645-gq92lcvppeh6nuiab0l6toeuof704rbk.apps.googleusercontent.com',
//         )
//         .then((_) {
//       _googleSignIn.authenticationEvents.listen((event) {
//         if (event is GoogleSignInAuthenticationEventSignIn) {
//           currentUser.value = event.user;
//         } else if (event is GoogleSignInAuthenticationEventSignOut) {
//           currentUser.value = null;
//         }
//       });
//       _googleSignIn.attemptLightweightAuthentication();
//     });
//   }

//   /// Interactive sign-in (foreground only)
//   Future<void> signIn() async {
//     try {
//       await _googleSignIn.authenticate(
//         scopeHint: driveScopes,
//       );
//     } catch (error) {
//       debugPrint("Google Sign-In Error: $error");
//       Get.snackbar('Sign-In Failed', 'Could not sign in. Please check your connection.');
//     }
//   }

//   Future<void> signOut() async {
//     await _googleSignIn.signOut();
//   }

//   /// Upload file to Drive
//   Future<bool> uploadFile(File file) async {
//     final user = currentUser.value;
//     if (user == null) {
//       debugPrint('Upload failed: User is not signed in.');
//       return false;
//     }

//     final client = _AuthHeadersClient(() async {
//       final authHeaders = await user.authorizationClient.authorizationHeaders( driveScopes);
//       return authHeaders;
//     });

//     try {
//       final driveApi = drive.DriveApi(client);
//       final driveFile = drive.File()..name = path.basename(file.path);
//       final media = drive.Media(file.openRead(), await file.length());

//       final created = await driveApi.files.create(
//         driveFile,
//         uploadMedia: media,
//       );
//       debugPrint('✅ Upload success: ${created.name} (${created.id})');
//       return true;
//     } on drive.DetailedApiRequestError catch (e) {
//       debugPrint('❌ Upload failed: Drive API error for ${file.path}');
//       debugPrint('--> Status: ${e.status}, Message: ${e.message}');
//       if (e.status == 401) {
//         _googleSignIn.attemptLightweightAuthentication();
//       }
//       return false;
//     } catch (e) {
//       debugPrint('❌ Upload failed: Generic error for ${file.path}: $e');
//       return false;
//     } finally {
//       client.close();
//     }
//   }
// }

// /// A client that injects fresh auth headers for every request.
// class _AuthHeadersClient extends http.BaseClient {
//   final http.Client _inner;
//   final Future<Map<String, String>?> Function() _getHeaders;

//   _AuthHeadersClient(this._getHeaders, [http.Client? inner])
//       : _inner = inner ?? http.Client();

//   @override
//   Future<http.StreamedResponse> send(http.BaseRequest request) async {
//     final headers = await _getHeaders();
//     if (headers == null) {
//       throw Exception('Authorization headers unavailable');
//     }
//     request.headers.addAll(headers);
//     return _inner.send(request);
//   }
// }
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart' as path;

// /// A service to manage Google Drive authentication and file uploads.
// class GoogleDriveService {
//   final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

//   final Rx<GoogleSignInAccount?> currentUser = Rx<GoogleSignInAccount?>(null);

//   GoogleDriveService() {
//     _initializeSignIn();
//   }

//   Future<void> _initializeSignIn() async {
//     await _googleSignIn.initialize(
//       clientId:
//           "868153586645-qrqrm6edsnfpj90jj4k729hrr0nnvra9.apps.googleusercontent.com",
//       serverClientId:
//           "868153586645-gq92lcvppeh6nuiab0l6toeuof704rbk.apps.googleusercontent.com",
//     );

//     _googleSignIn.authenticationEvents.listen((event) {
//       if (event is GoogleSignInAuthenticationEventSignIn) {
//         currentUser.value = event.user;
//       } else if (event is GoogleSignInAuthenticationEventSignOut) {
//         currentUser.value = null;
//       }
//     });

//     _googleSignIn.attemptLightweightAuthentication();
//   }

//   Future<void> signIn() async {
//     try {
//       await _googleSignIn.authenticate();
//     } catch (e) {
//       debugPrint("Sign-In Error: $e");
//       Get.snackbar('Sign-In Failed', 'Please try again.');
//     }
//   }

//   Future<void> signOut() async {
//     await _googleSignIn.signOut();
//   }

//   Future<bool> uploadFile(File file) async {
//     final user = currentUser.value;
//     if (user == null) {
//       debugPrint("❌ Upload failed: user not signed in.");
//       return false;
//     }

//     try {
//       // Get authentication tokens
//       final auth = await user.authentication;
//       final accessToken = auth.idToken;
//       if (accessToken == null) {
//         debugPrint("❌ Upload failed: accessToken is null.");
//         return false;
//       }

//       // Set headers with Bearer token
//       final headers = {
//         'Authorization': 'Bearer $accessToken',
//         'Content-Type': 'application/octet-stream',
//       };

//       // Example: Upload to Google Drive
//       final uri = Uri.parse(
//         "https://www.googleapis.com/upload/drive/v3/files?uploadType=media",
//       );

//       final request = http.Request("POST", uri)
//         ..headers.addAll(headers)
//         ..bodyBytes = await file.readAsBytes();

//       final response = await request.send();

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         debugPrint("✅ Upload success: ${file.path}");
//         return true;
//       } else {
//         final respStr = await response.stream.bytesToString();
//         debugPrint("❌ Upload failed: ${response.statusCode} - $respStr");
//         return false;
//       }
//     } catch (e) {
//       debugPrint("❌ Upload failed: $e");
//       return false;
//     }
//   }
// }

// class _AuthHeadersClient extends http.BaseClient {
//   final Map<String, String> _headers;
//   final http.Client _inner = http.Client();

//   _AuthHeadersClient(this._headers);

//   @override
//   Future<http.StreamedResponse> send(http.BaseRequest request) {
//     request.headers.addAll(_headers);
//     return _inner.send(request);
//   }
// }
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file', 
    ],
    clientId:
        '868153586645-qrqrm6edsnfpj90jj4k729hrr0nnvra9.apps.googleusercontent.com',
    serverClientId:
        '868153586645-gq92lcvppeh6nuiab0l6toeuof704rbk.apps.googleusercontent.com',
  );

  final Rx<GoogleSignInAccount?> currentUser = Rx<GoogleSignInAccount?>(null);

  GoogleDriveService() {
    _initializeSignIn();
  }

  void _initializeSignIn() {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      currentUser.value = account;
    });
    _googleSignIn.signInSilently();
  }

  Future<void> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      currentUser.value = account;
    } catch (e) {
      debugPrint("Sign-In Error: $e");
      Get.snackbar('Sign-In Failed', 'Please try again.');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    currentUser.value = null;
  }

  Future<bool> uploadFile(File file) async {
    final user = currentUser.value;
    if (user == null) {
      debugPrint("❌ Upload failed: user not signed in.");
      await signIn();
      return false;
    }

    final headers = await user.authHeaders;

    final client = _AuthHeadersClient(() async => headers);

    try {
      final driveApi = drive.DriveApi(client);
      final driveFile = drive.File()..name = path.basename(file.path);
      final media = drive.Media(file.openRead(), await file.length());

      final created = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
      debugPrint("✅ Uploaded: ${created.name} (${created.id})");
      return true;
    } catch (e) {
      debugPrint("❌ Upload failed: $e");
      return false;
    } finally {
      client.close();
    }
  }
}

class _AuthHeadersClient extends http.BaseClient {
  final http.Client _inner;
  final Future<Map<String, String>?> Function() _getHeaders;

  _AuthHeadersClient(this._getHeaders, [http.Client? inner])
    : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await _getHeaders();
    if (headers == null) throw Exception('Authorization headers unavailable');
    request.headers.addAll(headers);
    return _inner.send(request);
  }
}
