import 'dart:io';

import 'package:bluebubble_messages/helpers/attachment_downloader.dart';
import 'package:bluebubble_messages/helpers/utils.dart';
import 'package:bluebubble_messages/managers/contact_manager.dart';
import 'package:bluebubble_messages/repository/models/attachment.dart';
import 'package:bluebubble_messages/socket_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../helpers/hex_color.dart';
import '../../repository/models/message.dart';

class MessageWidget extends StatefulWidget {
  MessageWidget(
      {Key key,
      this.fromSelf,
      this.message,
      this.olderMessage,
      this.newerMessage})
      : super(key: key);

  final fromSelf;
  final Message message;
  final Message newerMessage;
  final Message olderMessage;

  @override
  _MessageState createState() => _MessageState();
}

class _MessageState extends State<MessageWidget> {
  List<Attachment> attachments = <Attachment>[];
  String body;
  List images = [];
  bool showTail = true;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    // Handle handle = await widget.message.from.update();
    // debugPrint("handle id is ${widget.message.from.address}");
  }

  @override
  void initState() {
    super.initState();
    if (widget.newerMessage != null) {
      showTail = withinTimeThreshold(widget.message, widget.newerMessage,
              threshold: 1) ||
          !sameSender(widget.message, widget.newerMessage);
    }

    // if (widget.message.hasAttachments) {
    Message.getAttachments(widget.message).then((data) {
      attachments = data;
      if (widget.message.text != null) {
        body = widget.message.text.substring(
            attachments.length); //ensure that the "obj" text doesn't appear
      }

      if (attachments.length > 0) {
        for (int i = 0; i < attachments.length; i++) {
          String appDocPath = SocketManager().appDocDir.path;
          String pathName =
              "$appDocPath/${attachments[i].guid}/${attachments[i].transferName}";
          if (FileSystemEntity.typeSync(pathName) !=
              FileSystemEntityType.notFound) {
            images.add(File(pathName));
          } else if (SocketManager()
              .attachmentDownloaders
              .containsKey(attachments[i].guid)) {
            images.add(
                SocketManager().attachmentDownloaders[attachments[i].guid]);
          } else {
            images.add(attachments[i]);
          }
        }
        setState(() {});
      }
    });
    // }
  }

  bool sameSender(Message first, Message second) {
    return (first != null &&
        second != null &&
        (first.isFromMe && second.isFromMe ||
            (!first.isFromMe &&
                !second.isFromMe &&
                first.handleId == second.handleId)));
  }

  bool withinTimeThreshold(Message first, Message second, {threshold: 5}) {
    if (first == null || second == null) return false;
    return first.dateCreated.difference(second.dateCreated).inMinutes >
        threshold;
  }

  List<Widget> _constructContent() {
    List<Widget> content = <Widget>[];
    for (int i = 0; i < images.length; i++) {
      if (images[i] is File) {
        content.add(Stack(
          children: <Widget>[
            Image.file(images[i]),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                ),
              ),
            ),
          ],
        ));
      } else if (images[i] is Attachment) {
        content.add(RaisedButton(
          onPressed: () {
            images[i] = new AttachmentDownloader(images[i]);
            setState(() {});
          },
          color: HexColor('26262a'),
          child: Text(
            "Download",
            style: TextStyle(color: Colors.white),
          ),
        ));
      } else if (images[i] is AttachmentDownloader) {
        content.add(
          StreamBuilder(
            stream: images[i].stream,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                return Text(
                  "Error loading",
                  style: TextStyle(color: Colors.white),
                );
              }
              // if (snapshot.hasData) {
              if (snapshot.data is File) {
                return InkWell(
                  onTap: () {
                    debugPrint("tap");
                  },
                  child: Image.file(snapshot.data),
                );
              } else {
                double progress = 0.0;
                if (snapshot.hasData) {
                  progress = snapshot.data["Progress"];
                } else {
                  progress = images[i].progress;
                }
                return CircularProgressIndicator(
                  value: progress,
                );
              }
              // } else {
              //   return Text(
              //     "Error loading",
              //     style: TextStyle(color: Colors.white),
              //   );
              // }
            },
          ),
        );
      } else {
        content.add(
          Text(
            "Error loading",
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    }
    if (widget.message.text != null &&
        widget.message.text.substring(attachments.length).length > 0) {
      content.add(
        Text(
          widget.message.text.substring(attachments.length),
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }
    return content;
  }

  Widget _buildSentMessage() {
    List<Widget> tail = <Widget>[
      Container(
        margin: EdgeInsets.only(bottom: 1),
        width: 20,
        height: 15,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
        ),
      ),
      Container(
        margin: EdgeInsets.only(bottom: 2),
        height: 28,
        width: 11,
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8))),
      ),
    ];

    List<Widget> stack = <Widget>[
      Container(
        height: 30,
        width: 6,
        color: Colors.black,
      ),
    ];
    if (showTail) {
      stack.insertAll(0, tail);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        _buildTimeStamp(),
        Padding(
          padding: EdgeInsets.only(bottom: showTail ? 10.0 : 3.0),
          child: Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: <Widget>[
              Stack(
                alignment: AlignmentDirectional.bottomEnd,
                children: stack,
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 3 / 4,
                ),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.blue,
                ),
                // color: Colors.blue,
                // height: 20,
                child: Column(
                  children: _constructContent(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceivedMessage() {
    List<Widget> tail = <Widget>[
      Container(
        margin: EdgeInsets.only(bottom: 1),
        width: 20,
        height: 15,
        decoration: BoxDecoration(
          color: HexColor('26262a'),
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
        ),
      ),
      Container(
        margin: EdgeInsets.only(bottom: 2),
        height: 28,
        width: 11,
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(8))),
      ),
    ];

    List<Widget> stack = <Widget>[
      Container(
        height: 30,
        width: 6,
        color: Colors.black,
      )
    ];
    if (showTail) {
      stack.insertAll(0, tail);
    }

    Widget contactItem = new Container(width: 0, height: 0);
    if (!sameSender(widget.message, widget.olderMessage)) {
      contactItem = Padding(
        padding: EdgeInsets.only(left: 25.0, top: 5.0, bottom: 3.0),
        child: Text(
          getContact(ContactManager().contacts, widget.message.handle.address),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTimeStamp(),
        contactItem,
        Padding(
          padding: EdgeInsets.only(bottom: showTail ? 10.0 : 3.0),
          child: Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: <Widget>[
              Stack(
                alignment: AlignmentDirectional.bottomStart,
                children: stack,
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 3 / 4,
                ),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: HexColor('26262a'),
                ),
                // color: Colors.blue,
                // height: 20,
                child: Column(
                  children: _constructContent(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeStamp() {
    if (widget.olderMessage != null &&
        withinTimeThreshold(widget.message, widget.olderMessage,
            threshold: 30)) {
      DateTime timeOfolderMessage = widget.olderMessage.dateCreated;
      String time = new DateFormat.jm().format(timeOfolderMessage);
      String date;
      if (widget.olderMessage.dateCreated.isToday()) {
        date = "Today";
      } else if (widget.olderMessage.dateCreated.isYesterday()) {
        date = "Yesterday";
      } else {
        date =
            "${timeOfolderMessage.month.toString()}/${timeOfolderMessage.day.toString()}/${timeOfolderMessage.year.toString()}";
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "$date, $time",
              style: TextStyle(
                color: Colors.white,
              ),
            )
          ],
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromSelf) {
      return _buildSentMessage();
    } else {
      return _buildReceivedMessage();
    }
  }
}
