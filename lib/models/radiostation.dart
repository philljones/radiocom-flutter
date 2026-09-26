class RadioStation {
  static const String fallbackStreamUrl =
      "https://stream.aberradio.com/test.mp3";

  String stationName;
  String iconUrl;
  String bigIconUrl;
  List<dynamic> stationPhotos;
  String history;
  double latitude;
  double longitude;
  String newsRss;
  String streamUrl;
  String facebookUrl;
  String blueskyUrl;

  RadioStation.base()
      : stationName = "Aber Radio",
        iconUrl = "assets/graphics/aber-radio-logo.png",
        bigIconUrl = "assets/graphics/aber-radio-logo.png",
        stationPhotos = ["https://aberradio.com/fb_cover_photo.png"],
        history =
            "<h3>Welcome to Aber Radio.</h3><p>Aber Radio is the Abergavenny Radio Project, building a community radio service for Abergavenny and the surrounding area.</p><p>Visit <a href=\"https://aberradio.com\">aberradio.com</a> or email <a href=\"mailto:studio@aberradio.com\">studio@aberradio.com</a> to find out more.</p>",
        latitude = 51.8254,
        longitude = -3.0194,
        newsRss = "https://aberradio.com/feed/",
        streamUrl = fallbackStreamUrl,
        facebookUrl = "https://aberradio.com",
        blueskyUrl = "https://aberradio.com";

  RadioStation.fromInstance(Map<String, dynamic> map)
      : stationName = map["station_name"] ?? "Aber Radio",
        iconUrl = map["icon_url"] ?? "assets/graphics/aber-radio-logo.png",
        bigIconUrl =
            map["big_icon_url"] ?? "assets/graphics/aber-radio-logo.png",
        stationPhotos = map["station_photos"],
        history = map["history"],
        latitude = map["latitude"],
        longitude = map["longitude"],
        newsRss = map["news_rss"],
        streamUrl = map["stream_url"] ?? fallbackStreamUrl,
        facebookUrl = map["facebook_url"],
        blueskyUrl = map["twitter_url"];
}
