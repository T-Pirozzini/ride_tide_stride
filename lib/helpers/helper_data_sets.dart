import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

List<Map<String, dynamic>> categories = [
  {
    'name': 'Alpine Skiing',
    'color': Colors.blue,
    'type': ['Snowboard', 'AlpineSki'],
    'icon': Icons.downhill_skiing_outlined,
    'distance': 2.0,
    'bestTime': '0:00',
  },
  {
    'name': 'Nordic Skiing',
    'color': Colors.red,
    'type': ['NordicSki'],
    'icon': Symbols.nordic_walking,
    'distance': 8.0,
    'bestTime': '0:00',
  },
  {
    'name': 'Road Running',
    'color': Colors.green,
    'type': ['VirtualRun', 'Road Run', 'Run'],
    'icon': Symbols.sprint,
    'distance': 7.0,
    'bestTime': '0:00',
  },
  {
    'name': 'Trail Running',
    'color': Colors.orange,
    'type': ['Trail Run'],
    'icon': Icons.directions_run_outlined,
    'distance': 6.0,
    'bestTime': '0:00',
  },
  {
    'name': 'Mountain Biking',
    'color': Colors.purple,
    'type': ['Mtn Bike'],
    'icon': Icons.directions_bike_outlined,
    'distance': 15.0,
    'bestTime': '0:00',
  },
  {
    'name': 'Kayaking',
    'color': Colors.teal,
    'type': ['Kayaking'],
    'icon': Icons.kayaking_outlined,
    'distance': 3.0,
    'bestTime': '0:00',
  },
  {
    'name': 'Road Cycling',
    'color': Colors.pink,
    'type': ['VirtualRide', 'Road Bike', 'Ride'],
    'icon': Icons.directions_bike_outlined,
    'distance': 25.0,
    'bestTime': '0:00',
  },
  {
    'name': 'Canoeing',
    'color': Colors.indigo,
    'type': ['Canoeing'],
    'icon': Icons.rowing_outlined,
    'distance': 5.0,
    'bestTime': '0:00',
  },
];

Map<String, dynamic> opponents = {
  "Intro": {
    "name": ["Dipsy", "La La", "Poe", "Tinky"],
    "image": [
      "assets/images/dipsy.jpg",
      "assets/images/lala.jpg",
      "assets/images/poe.jpg",
      "assets/images/tinky.jpg"
    ],
    "bestTimes": {
      "Alpine Skiing": "0:15:00",
      "Nordic Skiing": "0:50:00",
      "Road Running": "0:40:00",
      "Trail Running": "0:45:00",
      "Mountain Biking": "01:10:00",
      "Kayaking": "0:50:00",
      "Road Cycling": "01:15:00",
      "Canoeing": "1:15:00",
    },
    "teamName": "Teletubbies",
  },
  "Advanced": {
    "name": ["Crash", "Todd", "Noise", "Baldy"],
    "image": [
      "assets/images/crash.png",
      "assets/images/todd.png",
      "assets/images/noise.png",
      "assets/images/baldy.png"
    ],
    "bestTimes": {
      "Alpine Skiing": "0:10:00",
      "Nordic Skiing": "0:40:00",
      "Road Running": "0:30:00",
      "Trail Running": "0:35:00",
      "Mountain Biking": "0:50:00",
      "Kayaking": "0:42:00",
      "Road Cycling": "00:50:00",
      "Canoeing": "0:55:00",
    },
    "teamName": "Crash N' The Boys",
  },
  "Expert": {
    "name": ["Mike", "Leo", "Raph", "Don"],
    "image": [
      "assets/images/mike.jpg",
      "assets/images/leo.jpg",
      "assets/images/raph.jpg",
      "assets/images/don.jpg"
    ],
    "bestTimes": {
      "Alpine Skiing": "0:07:00",
      "Nordic Skiing": "0:30:00",
      "Road Running": "0:23:00",
      "Trail Running": "0:25:00",
      "Mountain Biking": "0:40:00",
      "Kayaking": "0:30:00",
      "Road Cycling": "0:40:00",
      "Canoeing": "0:45:00",
    },
    "teamName": "TMNT",
  },
};
