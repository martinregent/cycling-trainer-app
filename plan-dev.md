# **_Plan de Développement Flutter_**

_Application Cyclisme - Elite Suito & Whoop 5_

 __


# **_1. Vue d'Ensemble_**

_•    __Framework: Flutter 3.24+ / Dart 3.5+_

_•    __Plateformes: iPad 13 M3, MacBook Pro M1, iPhone (bonus)_

_•    __Bluetooth: Elite Suito (FTMS) + Whoop 5 (Heart Rate)_

_•    __Parcours: Import GPX depuis VeloViewer_

_•    __Export: Format FIT vers Strava_

_•    __Durée: 6-7 semaines_

 __


# **_2. Stack Technique_**

|                    |                        |               |
| :----------------: | :--------------------: | :-----------: |
|    **_Domaine_**   |      **_Package_**     | **_Version_** |
| _State Management_ |       _provider_       |    _^6.1.2_   |
|   _Bluetooth BLE_  |  _flutter\_blue\_plus_ |   _^1.32.11_  |
|      _Storage_     | _hive + hive\_flutter_ |    _^2.2.3_   |
|      _Maps 2D_     |     _flutter\_map_     |    _^7.0.2_   |
|      _Charts_      |       _fl\_chart_      |   _^0.69.0_   |
|    _GPX Parser_    |          _gpx_         |    _^2.2.2_   |
|    _Strava Auth_   |        _oauth2_        |    _^2.0.2_   |
|       _HTTP_       |         _http_         |    _^1.2.2_   |

 __


# **_3. Architecture MVVM + Provider_**

_Structure en 3 couches :_

_•    __UI Layer: Screens + Widgets (Flutter)_

_•    __Business Logic: Providers (BluetoothProvider, WorkoutProvider, RouteProvider)_

_•    __Data Layer: Services (FTMS, HeartRate, GPX, Strava) + Repositories (Hive)_

 __


# **_4. Gestion Bluetooth_**

## **_4.1 Services BLE_**

|                          |            |                       |
| :----------------------: | :--------: | :-------------------: |
|       **_Service_**      | **_UUID_** |   **_Périphérique_**  |
| _Fitness Machine (FTMS)_ |  _0x1826_  |     _Elite Suito_     |
|    _Indoor Bike Data_    |  _0x2AD2_  |     _Données FTMS_    |
|     _Machine Control_    |  _0x2AD9_  | _Contrôle résistance_ |
|       _Heart Rate_       |  _0x180D_  |       _Whoop 5_       |
|     _HR Measurement_     |  _0x2A37_  |     _Lecture BPM_     |

**_Données Indoor Bike Data (0x2AD2)_**

_•    __Byte 0-1: Flags (uint16)_

_•    __Byte 2-3: Vitesse (uint16 \* 0.01 km/h)_

_•    __Byte 4-5: Cadence (uint16 \* 0.5 RPM)_

_•    __Byte 6-7: Puissance (sint16 watts)_

 __


# **_5. Structure du Projet_**

    lib/ ├── main.dart ├── models/ │   ├── workout.dart │   ├── gpx_route.dart │   └── user_profile.dart ├── providers/ │   ├── bluetooth_provider.dart │   ├── workout_provider.dart │   └── route_provider.dart ├── services/ │   ├── bluetooth/ │   │   ├── ftms_service.dart │   │   └── heart_rate_service.dart │   ├── gpx_parser.dart │   ├── fit_exporter.dart │   └── strava_service.dart ├── screens/ │   ├── home_screen.dart │   ├── workout_screen.dart │   ├── route_library_screen.dart │   └── history_screen.dart └── widgets/ 	├── metric_tile.dart 	├── elevation_profile.dart 	└── route_map.dart

 __


# **_6. Planning de Développement_**

|                 |                                                       |                |
| :-------------: | :---------------------------------------------------: | :------------: |
|   **_Phase_**   |                      **_Tâches_**                     |   **_Durée_**  |
|   _1 - Setup_   |   _Install Flutter, config iOS/macOS, pubspec.yaml_   |   _2-3 jours_  |
| _2 - Bluetooth_ | _BluetoothProvider, FTMS, HeartRate, parsing données_ |   _1 semaine_  |
|  _3 - UI Base_  |  _HomeScreen, WorkoutScreen, MetricTile, navigation_  |   _1 semaine_  |
|    _4 - GPX_    |  _Parser GPX, flutter\_map, fl\_chart, RouteLibrary_  | _1.5 semaines_ |
|     _5 - 3D_    |      _Visualisation 3D terrain avec flutter\_gl_      | _1.5 semaines_ |
|  _6 - Storage_  |       _Hive models, repositories, HistoryScreen_      |   _3-4 jours_  |
|   _7 - Strava_  |            _FIT export, OAuth2, upload API_           |   _1 semaine_  |
|   _8 - Polish_  |        _Tests E2E, optimisations, corrections_        |   _1 semaine_  |
|     _TOTAL_     |                           __                          | _6-7 semaines_ |

 __


# **_7. Configuration Initiale_**

## **_7.1 Installation Flutter_**

    # Télécharger Flutter SDK curl -O https://storage.googleapis.com/flutter.../flutter_macos_arm64_3.24.0-stable.zip unzip flutter_macos_arm64_3.24.0-stable.zip sudo mv flutter /opt/flutter  # Ajouter au PATH (~/.zshrc) export PATH="$PATH:/opt/flutter/bin"  # Vérifier flutter doctor  # Créer projet flutter create cycling_trainer_app cd cycling_trainer_app


## **_7.2 iOS Info.plist_**

    <key>NSBluetoothAlwaysUsageDescription</key> <string>Connexion Elite Suito et Whoop 5</string> <key>UIBackgroundModes</key> <array><string>bluetooth-central</string></array>


## **_7.3 macOS Entitlements_**

    <key>com.apple.security.device.bluetooth</key> <true/>

 __


# **_8. Exemples de Code Essentiels_**

## **_8.1 main.dart_**

    import 'package:flutter/material.dart'; import 'package:provider/provider.dart';  void main() async {   await Hive.initFlutter();   runApp(MultiProvider( 	providers: [   	ChangeNotifierProvider(create: (_) => BluetoothProvider()),   	ChangeNotifierProvider(create: (_) => WorkoutProvider()), 	], 	child: MaterialApp(home: HomeScreen()),   )); }


## **_8.2 BluetoothProvider_**

    class BluetoothProvider extends ChangeNotifier {   double? power, cadence, speed;   int? heartRate;  	Future<void> connectToTrainer(BluetoothDevice device) async { 	await device.connect(); 	final service = await device.discoverServices(); 	// Subscribe to Indoor Bike Data (0x2AD2) 	characteristic.setNotifyValue(true); 	characteristic.value.listen((data) {   	power = parseUint16(data, 6);   	cadence = parseUint16(data, 4) * 0.5;   	notifyListeners(); 	});   } }


## **_8.3 GPX Parser_**

    class GPXParser {   Future<GPXRoute> parse(String gpxContent) async { 	final gpx = GpxReader().fromString(gpxContent); 	List<TrackPoint> points = []; 	double totalDistance = 0.0, elevationGain = 0.0;      	for (var pt in gpx.trks.first.trksegs.first.trkpts) {   	// Calculer distance cumulative (Haversine)   	// Calculer pente   	points.add(TrackPoint(     	lat: pt.lat!, lon: pt.lon!,      	ele: pt.ele, distance: totalDistance   	)); 	} 	return GPXRoute(points: points,	    totalDistance: totalDistance,    	elevationGain: elevationGain);   } }

 __


# **_9. Build et Déploiement_**

## **_9.1 Build iOS_**

    # Build release flutter build ios --release  # Ouvrir dans Xcode pour signing open ios/Runner.xcworkspace  # Dans Xcode: Product > Archive > Distribute


## **_9.2 Build macOS_**

    flutter build macos --release # App dans build/macos/Build/Products/Release/

 __


# **_10. Ressources_**

_•    __Flutter: https\://flutter.dev_

_•    __flutter\_blue\_plus: https\://pub.dev/packages/flutter\_blue\_plus_

_•    __FTMS Spec: https\://www\.bluetooth.com/specifications/specs/fitness-machine-service/_

_•    __Strava API: https\://developers.strava.com_

_•    __qDomyos-Zwift: https\://github.com/cagnulein/qdomyos-zwift_

**_Bon développement ! 🚴‍♂️_**
