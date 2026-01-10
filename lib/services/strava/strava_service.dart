import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class StravaService extends ChangeNotifier {
  static const String _authUrl = 'https://www.strava.com/oauth/mobile/authorize';
  static const String _tokenUrl = 'https://www.strava.com/oauth/token';
  static const String _redirectUrl = 'cyclingtrainer://oauth/callback';
  
  // Credentials (should be secure in real app)
  final String clientId;
  final String clientSecret;
  
  String? _accessToken;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  StravaService({required this.clientId, required this.clientSecret}) {
    // Automatically initialize on construction
    initialize();
  }

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;

  void initialize() {
    try {
      _appLinks = AppLinks();
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          debugPrint('Deep Link received: $uri');
          if (uri.toString().startsWith('cyclingtrainer://oauth/callback')) {
            handleRedirect(uri);
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing AppLinks: $e');
    }
  }

  @override
  void dispose() {
    try {
      _linkSubscription?.cancel();
    } catch (e) {
      debugPrint('Error disposing AppLinks: $e');
    }
    super.dispose();
  }

  // OAuth Flow - Step 1: Start Authorization (Manual OAuth approach)
  Future<void> authenticate() async {
    try {
      // Build authorization URL manually (avoids oauth2 library scope encoding issues)
      final authUrl = Uri.parse(_authUrl).replace(
        queryParameters: {
          'client_id': clientId,
          'response_type': 'code',
          'redirect_uri': _redirectUrl,
          'scope': 'activity:write,activity:read_all',
          'approval_prompt': 'force', // Force approval for new authorizations
        },
      );

      debugPrint('Launching Strava OAuth URL: $authUrl');

      // Launch the URL in the browser
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $authUrl';
      }
    } catch (e) {
      debugPrint('Error in authenticate: $e');
      rethrow;
    }
  }

  // OAuth Flow - Step 2: Handle Redirect and Get Token
  Future<void> handleRedirect(Uri redirectUri) async {
    final code = redirectUri.queryParameters['code'];
    if (code == null) {
      debugPrint('No code in redirect URI');
      return;
    }

    try {
      await exchangeCodeForToken(code);
      notifyListeners(); // Notify UI that we are authenticated
      debugPrint('Strava Authenticated successfully');
    } catch (e) {
      debugPrint('Error exchanging token: $e');
    }
  }

  Future<void> exchangeCodeForToken(String code) async {
    try {
      debugPrint('Exchanging auth code for access token...');

      final response = await http.post(
        Uri.parse(_tokenUrl),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      debugPrint('Token exchange response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        _accessToken = tokenData['access_token'] as String?;

        if (_accessToken != null) {
          debugPrint('Strava Authentication successful! Token: ${_accessToken!.substring(0, 10)}...');
          notifyListeners();
        } else {
          throw Exception('No access_token in response: ${response.body}');
        }
      } else {
        debugPrint('Token exchange failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to exchange token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in exchangeCodeForToken: $e');
      rethrow;
    }
  }

  Future<void> uploadActivity(Uint8List fitData, String name, String? description) async {
    if (_accessToken == null) throw Exception('Not authenticated - no access token');

    try {
      final uri = Uri.parse('https://www.strava.com/api/v3/uploads');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_accessToken';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fitData,
        filename: 'activity.fit',
      ));

      request.fields['name'] = name;
      request.fields['data_type'] = 'fit';
      if (description != null) {
        request.fields['description'] = description;
      }

      debugPrint('Uploading activity to Strava: $name (${fitData.length} bytes)');

      final response = await request.send();

      debugPrint('Strava upload response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        debugPrint('Upload successful: $respStr');
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('Upload failed - Status: ${response.statusCode}');
        debugPrint('Response: $respStr');
        throw Exception('Upload failed with status: ${response.statusCode}, body: $respStr');
      }
    } catch (e) {
      debugPrint('Error uploading activity: $e');
      rethrow;
    }
  }
}
