import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
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
  
  oauth2.Client? _client;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  StravaService({required this.clientId, required this.clientSecret});

  bool get isAuthenticated => _client?.credentials.accessToken != null;

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

  // OAuth Flow - Step 1: Start Authorization
  Future<void> authenticate() async {
    final grant = oauth2.AuthorizationCodeGrant(
      clientId,
      Uri.parse(_authUrl),
      Uri.parse(_tokenUrl),
      secret: clientSecret,
    );
    
    // Construct the authorization URL
    var authorizationUrl = grant.getAuthorizationUrl(
      Uri.parse(_redirectUrl),
      scopes: ['activity:write', 'activity:read_all'],
    );
    
    // Launch the URL in the browser
    if (await canLaunchUrl(authorizationUrl)) {
      await launchUrl(authorizationUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $authorizationUrl';
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
    final response = await http.post(
      Uri.parse(_tokenUrl),
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      // Manually creating client for now as simple usage
      // In a real app we'd use Credentials.fromJson and handle refresh
      // For this demo, we assume the token is valid for the session or short term
      final credentials = oauth2.Credentials.fromJson(response.body);
      _client = oauth2.Client(credentials, identifier: clientId, secret: clientSecret);
    } else {
      throw Exception('Failed to exchange token: ${response.body}');
    }
  }

  Future<void> uploadActivity(Uint8List fitData, String name, String? description) async {
    if (_client == null) throw Exception('Not authenticated');

    final uri = Uri.parse('https://www.strava.com/api/v3/uploads');
    
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${_client!.credentials.accessToken}';
    
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

    final response = await request.send();
    
    if (response.statusCode != 201) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Upload failed with status: ${response.statusCode}, body: $respStr');
    }
  }
}
