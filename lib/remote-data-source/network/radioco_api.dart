abstract class RadiocoAPIContract {
  String baseUrl = "";
  String radioStation = "";
  String podcast = "";
  String timetable = "";
  String timetableAfter = "";
  String timetableBefore = "";
  String live = "";
  String feedUrl = "";
  String outstandingUrl = "";
  String outstandingUrl2 = "";
}

class RadiocoAPI implements RadiocoAPIContract {
  @override
  String baseUrl = "https://api.aberradio.com/api/2/";
  @override
  String radioStation = "radiocom/radiostation?format=json";
  @override
  String podcast = "programmes?format=json&ordering=name";
  @override
  String timetable = "radiocom/transmissions?format=json&timezone=Europe/London";
  @override
  String timetableAfter = "&after=";
  @override
  String timetableBefore = "&before=";
  @override
  String live = "radiocom/transmissions/now?format=json&timezone=Europe/London";
  @override
  String feedUrl = "https://api.aberradio.com/feed.xml";
  @override
  String outstandingUrl = "https://api.aberradio.com/api/2/outstanding/1";
  @override
  String outstandingUrl2 = "https://api.aberradio.com/api/2/outstanding/2";
}
