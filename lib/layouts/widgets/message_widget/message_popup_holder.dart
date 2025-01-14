import 'package:bluebubbles/action_handler.dart';
import 'package:bluebubbles/blocs/message_bloc.dart';
import 'package:bluebubbles/helpers/constants.dart';
import 'package:bluebubbles/helpers/hex_color.dart';
import 'package:bluebubbles/helpers/logger.dart';
import 'package:bluebubbles/helpers/message_helper.dart';
import 'package:bluebubbles/helpers/themes.dart';
import 'package:bluebubbles/helpers/utils.dart';
import 'package:bluebubbles/layouts/titlebar_wrapper.dart';
import 'package:bluebubbles/layouts/widgets/message_widget/message_details_popup.dart';
import 'package:bluebubbles/layouts/widgets/vertical_split_view.dart';
import 'package:bluebubbles/managers/chat/chat_controller.dart';
import 'package:bluebubbles/managers/chat/chat_manager.dart';
import 'package:bluebubbles/managers/event_dispatcher.dart';
import 'package:bluebubbles/managers/life_cycle_manager.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/repository/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:universal_html/html.dart' as html;

class MessagePopupHolder extends StatefulWidget {
  final Widget child;
  final Widget popupChild;
  final Message message;
  final Message? olderMessage;
  final Message? newerMessage;
  final Function(bool) popupPushed;
  final MessageBloc? messageBloc;

  MessagePopupHolder({
    Key? key,
    required this.child,
    required this.popupChild,
    required this.message,
    required this.olderMessage,
    required this.newerMessage,
    required this.popupPushed,
    required this.messageBloc,
  }) : super(key: key);

  @override
  State<MessagePopupHolder> createState() => _MessagePopupHolderState();
}

class _MessagePopupHolderState extends State<MessagePopupHolder> {
  GlobalKey containerKey = GlobalKey();
  double childOffsetY = 0;
  Size? childSize;
  bool visible = true;

  void getOffset() {
    RenderBox renderBox = containerKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    bool increaseWidth = !MessageHelper.getShowTail(context, widget.message, widget.newerMessage) &&
        (SettingsManager().settings.alwaysShowAvatars.value || (ChatManager().activeChat?.chat.isGroup() ?? false));
    bool doNotIncreaseHeight = ((widget.message.isFromMe ?? false) ||
        !(ChatManager().activeChat?.chat.isGroup() ?? false) ||
        !sameSender(widget.message, widget.olderMessage) ||
        !widget.message.dateCreated!.isWithin(widget.olderMessage!.dateCreated!, minutes: 30));

    childOffsetY = offset.dy -
        (doNotIncreaseHeight
            ? 0
            : widget.message.getReactions().isNotEmpty
                ? 20.0
                : 23.0);
    childSize = Size(
        size.width + (increaseWidth ? 35 : 0),
        size.height +
            (doNotIncreaseHeight
                ? 0
                : widget.message.getReactions().isNotEmpty
                    ? 20.0
                    : 23.0));
  }

  void openMessageDetails(bool keyboardStatus) async {
    EventDispatcher().emit("unfocus-keyboard", null);
    HapticFeedback.lightImpact();
    getOffset();

    if (mounted) {
      setState(() {
        visible = false;
      });
    }

    EventDispatcher().emit('popup-pushed', true);
    widget.popupPushed.call(true);
    await Navigator.push(
      Get.context ?? context,
      PageRouteBuilder(
        settings: RouteSettings(arguments: {"hideTail": true}),
        transitionDuration: Duration(milliseconds: 150),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Theme(
              data: context.theme.copyWith(
                // in case some components still use legacy theming
                primaryColor: context.theme.colorScheme.bubble(context, true),
                colorScheme: context.theme.colorScheme.copyWith(
                  primary: context.theme.colorScheme.bubble(context, true),
                  onPrimary: context.theme.colorScheme.onBubble(context, true),
                  surface: SettingsManager().settings.monetTheming.value == Monet.full ? null : (context.theme.extensions[BubbleColors] as BubbleColors?)?.receivedBubbleColor,
                  onSurface: SettingsManager().settings.monetTheming.value == Monet.full ? null : (context.theme.extensions[BubbleColors] as BubbleColors?)?.onReceivedBubbleColor,
                ),
              ),
              child: buildForDevice(),
            ),
          );
        },
        fullscreenDialog: true,
        opaque: false,
      ),
    );
    EventDispatcher().emit('popup-pushed', false);
    widget.popupPushed.call(false);
    if (keyboardStatus || kIsDesktop || kIsWeb) EventDispatcher().emit('focus-keyboard', null);
    if (mounted) {
      setState(() {
        visible = true;
      });
    }
  }

  void sendReaction(String type) {
    Logger.info("Sending reaction type: $type");
    ActionHandler.sendReaction(widget.message.getChat() ?? ChatManager().activeChat!.chat, widget.message, type);
  }

  Widget buildForDevice() {
    bool showAltLayout =
        SettingsManager().settings.tabletMode.value && (!context.isPhone || context.isLandscape) && context.width > 600 && !LifeCycleManager().isBubble;

    ChatController? currentChat = ChatManager().activeChat;
    Widget popup = MessageDetailsPopup(
      currentChat: currentChat,
      child: widget.popupChild,
      childOffsetY: childOffsetY,
      childSize: childSize,
      message: widget.message,
      newerMessage: widget.newerMessage,
      messageBloc: widget.messageBloc,
    );

    if (showAltLayout) {
      return VerticalSplitView(
          allowResize: false,
          left: GestureDetector(onTap: () => Navigator.pop(Get.context ?? context)),
          right: popup,
        dividerWidth: 0,
      );
    } else {
      return TitleBarWrapper(child: popup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(builder: (context, isVisible) {
      return GestureDetector(
        key: containerKey,
        onDoubleTap: SettingsManager().settings.doubleTapForDetails.value && !widget.message.guid!.startsWith('temp')
            ? () => openMessageDetails(isVisible)
            : SettingsManager().settings.enableQuickTapback.value && (ChatManager().activeChat?.chat.isIMessage ?? true)
                ? () {
                    if (widget.message.guid!.startsWith('temp')) return;
                    if (kIsDesktop &&
                        (ChatManager()
                                .activeChat
                                ?.videoPlayersDesktop
                                .keys
                                .any((String guid) => widget.message.attachments.any((a) => a?.guid == guid)) ??
                            false)) {
                      return;
                    }
                    HapticFeedback.lightImpact();
                    sendReaction(SettingsManager().settings.quickTapbackType.value);
                  }
                : null,
        onLongPress: SettingsManager().settings.doubleTapForDetails.value &&
                SettingsManager().settings.enableQuickTapback.value &&
                (ChatManager().activeChat?.chat.isIMessage ?? true)
            ? () {
                if (widget.message.guid!.startsWith('temp')) return;
                HapticFeedback.lightImpact();
                sendReaction(SettingsManager().settings.quickTapbackType.value);
              }
            : () => openMessageDetails(isVisible),
        onSecondaryTapUp: (details) async {
          if (!kIsWeb && !kIsDesktop) return;
          if (kIsWeb) {
            (await html.document.onContextMenu.first).preventDefault();
          }
          openMessageDetails(isVisible);
        },
        child: Opacity(
          child: widget.child,
          opacity: visible ? 1 : 0,
        ),
      );
    });
  }
}