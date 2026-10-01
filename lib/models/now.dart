import 'package:cuacfm/models/radiostation.dart';
import 'package:injector/injector.dart';

class Now {
  String name;
  String description;
  String programmeUrl;
  String logoUrl;
  String rssUrl;
  String trackTitle;
  String trackArtist;

  Now.mock()
      : name = "Aber Radio",
        logoUrl = "assets/graphics/aber-radio-logo.png",
        description = "",
        programmeUrl = "https://aberradio.com",
        rssUrl = "https://aberradio.com",
        trackTitle = "",
        trackArtist = "";

  Now.fromInstance(Map<String, dynamic> map)
      : name = map["name"] ?? "Aber Radio",
        description = map["description"],
        programmeUrl = map["programme_url"] ?? "https://aberradio.com",
        logoUrl = map["logo_url"] ?? "assets/graphics/aber-radio-logo.png",
        rssUrl = map["rss_url"],
        trackTitle = map["track"] is Map
            ? (map["track"]["title"] ?? "").toString().trim()
            : "",
        trackArtist = map["track"] is Map
            ? (map["track"]["artist"] ?? "").toString().trim()
            : "";

  String get trackDisplay {
    if (trackTitle.isEmpty) return "";
    return trackArtist.isEmpty ? trackTitle : "$trackArtist — $trackTitle";
  }

  String streamUrl() {
    return Injector.appInstance.get<RadioStation>().streamUrl;
  }
}
