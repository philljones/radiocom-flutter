import 'package:cuacfm/models/radiostation.dart';
import 'package:injector/injector.dart';

class Now {
  String name;
  String description;
  String programmeUrl;
  String logoUrl;
  String rssUrl;

  Now.mock()
      : name = "Aber Radio",
        logoUrl = "assets/graphics/aber-radio-logo.png",
        description = "",
        programmeUrl = "https://aberradio.com",
        rssUrl = "https://aberradio.com";

  Now.fromInstance(Map<String, dynamic> map)
      : name = map["name"] ?? "Aber Radio",
        description = map["description"],
        programmeUrl = map["programme_url"] ?? "https://aberradio.com",
        logoUrl = map["logo_url"] ?? "assets/graphics/aber-radio-logo.png",
        rssUrl = map["rss_url"];

  String streamUrl() {
    return Injector.appInstance.get<RadioStation>().streamUrl;
  }
}
