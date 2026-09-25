import 'package:cuacfm/models/radiostation.dart';
import 'package:injector/injector.dart';

class Now {
  String name;
  String description;
  String programmeUrl;
  String logoUrl;
  String rssUrl;

  Now.mock()
      : name = "Aber Radio Live",
        logoUrl = "assets/graphics/aber-radio-logo.png",
        description = "",
        programmeUrl = "https://aberradio.com",
        rssUrl = "https://aberradio.com";

  Now.fromInstance(Map<String, dynamic> map)
      : name = "Aber Radio Live",
        description = map["description"],
        programmeUrl = "https://aberradio.com",
        logoUrl = "assets/graphics/aber-radio-logo.png",
        rssUrl = map["rss_url"];

  String streamUrl() {
    return Injector.appInstance.get<RadioStation>().streamUrl;
  }
}
