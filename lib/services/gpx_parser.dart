import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import '../models/gpx_route.dart';
import 'package:uuid/uuid.dart';

class GPXParserService {
  final GpxReader _reader = GpxReader();
  final Uuid _uuid = const Uuid();

  /// Parse GPX XML content string into a GPXRoute object
  /// Calculates cumulative distances and slopes between points
  Future<GPXRoute> parse(String xmlContent, {String? name}) async {
    try {
      final gpx = _reader.fromString(xmlContent);
      final trackPoints = <TrackPoint>[];
      
      double totalDistance = 0;
      double elevationGain = 0;
      
      if (gpx.trks.isNotEmpty && gpx.trks.first.trksegs.isNotEmpty) {
        final points = gpx.trks.first.trksegs.first.trkpts;
        
        if (points.isNotEmpty) {
          // Add first point
          final firstPt = points.first;
          trackPoints.add(TrackPoint(
            latitude: firstPt.lat ?? 0,
            longitude: firstPt.lon ?? 0,
            elevation: firstPt.ele ?? 0,
            distance: 0,
            slope: 0,
          ));
          
          // Process remaining points
          for (int i = 1; i < points.length; i++) {
            final prev = points[i - 1];
            final curr = points[i];
            
            final prevLat = prev.lat ?? 0;
            final prevLon = prev.lon ?? 0;
            final prevEle = prev.ele ?? 0;
            
            final currLat = curr.lat ?? 0;
            final currLon = curr.lon ?? 0;
            final currEle = curr.ele ?? 0;
            
            // Calculate distance
            const Distance distanceCalc = Distance();
            final segmentDist = distanceCalc(
              LatLng(prevLat, prevLon),
              LatLng(currLat, currLon),
            );
            
            totalDistance += segmentDist;
            
            // Calculate slope (%)
            double slope = 0;
            if (segmentDist > 0) {
              slope = ((currEle - prevEle) / segmentDist) * 100;
            }
            
            // Calculate elevation gain (only positive elevation changes)
            if (currEle > prevEle) {
              elevationGain += (currEle - prevEle);
            }
            
            trackPoints.add(TrackPoint(
              latitude: currLat,
              longitude: currLon,
              elevation: currEle,
              distance: totalDistance,
              slope: slope,
            ));
          }
        }
      }

      // Use provided name or filename from metadata, or default
      String routeName = name ?? gpx.metadata?.name ?? 'Parcours importé';
      String? description = gpx.metadata?.desc;

      return GPXRoute(
        id: _uuid.v4(),
        name: routeName,
        description: description,
        distance: totalDistance,
        elevationGain: elevationGain,
        gpxData: xmlContent,
        createdDate: DateTime.now(),
        trackPoints: trackPoints,
      );
    } catch (e) {
      throw Exception('Erreur lors du parsing GPX: $e');
    }
  }
}
