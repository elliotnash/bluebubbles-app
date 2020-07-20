import 'dart:async';
import 'dart:io';

import 'package:bluebubble_messages/helpers/hex_color.dart';
import 'package:bluebubble_messages/layouts/image_viewer/video_viewer.dart';
import 'package:bluebubble_messages/layouts/widgets/message_widget/message_content/message_attachments.dart';
import 'package:bluebubble_messages/repository/models/attachment.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  VideoWidget({Key key, this.file, this.attachment, this.savedAttachmentData})
      : super(key: key);
  final File file;
  final Attachment attachment;
  final SavedAttachmentData savedAttachmentData;

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  // VideoPlayerController widget.savedAttachmentData.controller;

  bool showPlayPauseOverlay = true;
  Timer hideOverlayTimer;

  @override
  void initState() {
    super.initState();
    debugPrint("height ${widget.attachment.width}");
    if (widget.savedAttachmentData.controller == null) {
      widget.savedAttachmentData.controller =
          VideoPlayerController.file(widget.file)
            ..initialize().then((value) {
              // widget.savedAttachmentData.controller.play();
              setState(() {});
            });
    }
    showPlayPauseOverlay =
        !widget.savedAttachmentData.controller.value.isPlaying;
    widget.savedAttachmentData.controller.setLooping(true);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: GestureDetector(
        onTap: () {
          if (widget.savedAttachmentData.controller.value.isPlaying) {
            widget.savedAttachmentData.controller.pause();
            setState(() {
              showPlayPauseOverlay = true;
            });
          } else {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => VideoViewer(
                  controller: widget.savedAttachmentData.controller,
                  heroTag: widget.attachment.guid,
                ),
              ),
            );
          }
        },
        child: widget.savedAttachmentData.controller.value.aspectRatio != null
            ? Hero(
                tag: widget.attachment.guid,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: widget
                          .savedAttachmentData.controller.value.aspectRatio,
                      child: Stack(
                        children: <Widget>[
                          VideoPlayer(widget.savedAttachmentData.controller),
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: showPlayPauseOverlay ? 1 : 0,
                      duration: Duration(milliseconds: 250),
                      child: Container(
                        decoration: BoxDecoration(
                          color: HexColor('26262a').withOpacity(0.5),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: EdgeInsets.all(10),
                        child: widget
                                .savedAttachmentData.controller.value.isPlaying
                            ? GestureDetector(
                                child: Icon(
                                  Icons.pause,
                                  color: Colors.white,
                                  size: 45,
                                ),
                                onTap: () {
                                  widget.savedAttachmentData.controller.pause();
                                  setState(() {
                                    showPlayPauseOverlay = true;
                                  });
                                },
                              )
                            : GestureDetector(
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 45,
                                ),
                                onTap: () {
                                  widget.savedAttachmentData.controller.play();
                                  setState(() {
                                    showPlayPauseOverlay = false;
                                  });
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(),
      ),
    );
  }
}