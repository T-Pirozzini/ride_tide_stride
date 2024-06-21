import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_tide_stride/models/opponent.dart';

final opponentsProvider = Provider<Map<String, Opponent>>((ref) {
  return {
    "Intro": Opponent.fromMap({
      "name": ["Dipsy", "La La", "Poe", "Tinky"],
      "activity": ["Walk", "StandUpPaddling", 'Snowshoe', 'IceSkate'],
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
      "distanceMax": 5.0,
      "slogan": {
        "Dipsy": "Dipsy Dashes to Victory!",
        "La La": "La La Leads the Way!",
        "Poe": "Poe Powers Through!",
        "Tinky": "Tinky Winky Takes the Win!",
      }
    }),
    "Advanced": Opponent.fromMap({
      "name": ["Crash", "Todd", "Noise", "Baldy"],
      "activity": ["Run", "Ride", 'Kayaking', 'Swim'],
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
      "distanceMax": 10.0,
      "slogan": {
        "Crash": "Crash Leaves You in the Dust!",
        "Todd": "Todd Tears You Apart!",
        "Noise": "Noise Knows No Limits!",
        "Baldy": "Baldy Makes Winning Look Easy!",
      }
    }),
    "Expert": Opponent.fromMap({
      "name": ["Mike", "Leo", "Raph", "Don"],
      "activity": ["Skateboard", 'Surfing', 'Motorbike', 'Van'],
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
      "distanceMax": 30.0,
      "slogan": {
        "Mike": "Cowabunga, dudes! Too fast for you!",
        "Leo": "Disciplined, determined, and destined to win!",
        "Raph": "Out of my way!",
        "Don": "Tech-powered and turbocharged!",
      }
    }),
  };
});
