import 'dart:convert';

class Message {
  String guid;
  String text;
  String chatGuid;
  int dateCreated;
  String attachments;
  bool isFromMe;

  Message.manual(this.text, this.chatGuid, this.dateCreated, this.attachments);

  Message(Map data) {
    this.guid = data["guid"];
    this.text = data["text"];
    this.chatGuid = data["chats"][0]["guid"];
    this.dateCreated = data["dateCreated"];
    this.attachments = jsonEncode(data["attachments"]);
    this.isFromMe = data["isFromMe"];
  }

  Message.fromJson(Map<String, dynamic> json) {
    this.guid = json["guid"];
    this.text = json["text"];
    this.chatGuid = json["chatGuid"];
    this.dateCreated = json["dateCreated"];
    this.attachments = json["attachments"];
    this.isFromMe = json["isFromMe"] == 1;
  }
}