import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapRouteWidget extends StatelessWidget {
  final Map<String, dynamic> activityData;

  List<LatLng> decodePolyline(String encoded) {
    final polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates = [];

    List<PointLatLng> points = polylinePoints.decodePolyline(encoded);

    if (points.isNotEmpty) {
      points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    return polylineCoordinates;
  }

  MapRouteWidget({Key? key, required this.activityData}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Extract route polyline coordinates
//     final List<LatLng> routeCoordinates =
//         decodePolyline(activityData['map']['summary_polyline']);

//     return FlutterMap(
//       options: MapOptions(
//         center:
//             routeCoordinates.isNotEmpty ? routeCoordinates.first : LatLng(0, 0),
//         zoom: 13.0, // Adjust the zoom level as needed
//       ),
//       children: [
//         TileLayerWidget(
//           options: TileLayerOptions(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: ['a', 'b', 'c'],
//           ),
//         ),
//         PolylineLayerWidget(
//           options: PolylineLayerOptions(
//             polylines: [
//               Polyline(
//                 points: routeCoordinates,
//                 color: Colors.blue, // Set the color of the route line
//                 strokeWidth: 3.0, // Adjust the width of the route line
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(51.5, -0.09), // Initial center coordinates
        zoom: 13.0, // Initial zoom level
      ),
    );
  }
}
