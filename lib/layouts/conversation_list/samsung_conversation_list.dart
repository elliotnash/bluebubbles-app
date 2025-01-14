import 'package:bluebubbles/blocs/chat_bloc.dart';
import 'package:bluebubbles/helpers/constants.dart';
import 'package:bluebubbles/helpers/hex_color.dart';
import 'package:bluebubbles/helpers/navigator.dart';
import 'package:bluebubbles/helpers/ui_helpers.dart';
import 'package:bluebubbles/helpers/utils.dart';
import 'package:bluebubbles/layouts/conversation_list/conversation_list.dart';
import 'package:bluebubbles/layouts/conversation_list/conversation_tile.dart';
import 'package:bluebubbles/layouts/conversation_view/conversation_view.dart';
import 'package:bluebubbles/layouts/scrollbar_wrapper.dart';
import 'package:bluebubbles/layouts/search/search_view.dart';
import 'package:bluebubbles/layouts/titlebar_wrapper.dart';
import 'package:bluebubbles/layouts/widgets/theme_switcher/theme_switcher.dart';
import 'package:bluebubbles/layouts/widgets/vertical_split_view.dart';
import 'package:bluebubbles/main.dart';
import 'package:bluebubbles/managers/chat/chat_manager.dart';
import 'package:bluebubbles/managers/event_dispatcher.dart';
import 'package:bluebubbles/managers/life_cycle_manager.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/managers/theme_manager.dart';
import 'package:bluebubbles/repository/models/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class SamsungConversationList extends StatefulWidget {
  SamsungConversationList({Key? key, required this.parent}) : super(key: key);

  final ConversationListState parent;

  @override
  State<SamsungConversationList> createState() => _SamsungConversationListState();
}

class _SamsungConversationListState extends State<SamsungConversationList> {
  List<Chat> selected = [];
  bool openedChatAlready = false;
  final ScrollController scrollController = ScrollController();
  final RxDouble remainingHeight = RxDouble(0);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // this is so that we can still have the snap header effect on the chat
      // list even if the number of chats is not enough to scroll
      await ChatBloc().chatRequest?.future;
      final padding = MediaQuery.of(context).viewPadding;
      double actualHeight = context.height - padding.top - padding.bottom;
      if (scrollController.position.viewportDimension < actualHeight) {
        remainingHeight.value =
            context.height - scrollController.position.viewportDimension + (context.height / 3 - (kToolbarHeight + (kIsDesktop ? 20 : 0)));
      } else if (scrollController.position.maxScrollExtent < context.height / 3 - (kToolbarHeight + (kIsDesktop ? 20 : 0))) {
        remainingHeight.value = context.height / 3 - (kToolbarHeight + (kIsDesktop ? 20 : 0)) - scrollController.position.maxScrollExtent;
      }
    });
  }

  bool hasPinnedChat() {
    for (int i = 0;
        i <
            ChatBloc()
                .chats
                .archivedHelper(widget.parent.widget.showArchivedChats)
                .unknownSendersHelper(widget.parent.widget.showUnknownSenders)
                .length;
        i++) {
      if (ChatBloc()
          .chats
          .archivedHelper(widget.parent.widget.showArchivedChats)
          .unknownSendersHelper(widget.parent.widget.showUnknownSenders)[i]
          .isPinned!) {
        widget.parent.hasPinnedChats = true;
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  bool hasNormalChats() {
    int counter = 0;
    for (int i = 0;
        i <
            ChatBloc()
                .chats
                .archivedHelper(widget.parent.widget.showArchivedChats)
                .unknownSendersHelper(widget.parent.widget.showUnknownSenders)
                .length;
        i++) {
      if (ChatBloc()
          .chats
          .archivedHelper(widget.parent.widget.showArchivedChats)
          .unknownSendersHelper(widget.parent.widget.showUnknownSenders)[i]
          .isPinned!) {
        counter++;
      } else {}
    }
    if (counter ==
        ChatBloc()
            .chats
            .archivedHelper(widget.parent.widget.showArchivedChats)
            .unknownSendersHelper(widget.parent.widget.showUnknownSenders)
            .length) {
      return false;
    } else {
      return true;
    }
  }

  Widget slideLeftBackground(Chat chat) {
    return Container(
      color: SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.pin
          ? Colors.yellow[800]
          : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.alerts
              ? Colors.purple
              : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.delete
                  ? Colors.red
                  : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.mark_read
                      ? Colors.blue
                      : Colors.red,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(
              SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.pin
                  ? (chat.isPinned! ? Icons.star_outline : Icons.star)
                  : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.alerts
                      ? (chat.muteType == "mute" ? Icons.notifications_active : Icons.notifications_off)
                      : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.delete
                          ? Icons.delete_forever
                          : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.mark_read
                              ? (chat.hasUnreadMessage! ? Icons.mark_chat_read : Icons.mark_chat_unread)
                              : (chat.isArchived! ? Icons.unarchive : Icons.archive),
              color: Colors.white,
            ),
            Text(
              SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.pin
                  ? (chat.isPinned! ? " Unpin" : " Pin")
                  : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.alerts
                      ? (chat.muteType == "mute" ? ' Show Alerts' : ' Hide Alerts')
                      : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.delete
                          ? " Delete"
                          : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.mark_read
                              ? (chat.hasUnreadMessage! ? ' Mark Read' : ' Mark Unread')
                              : (chat.isArchived! ? ' UnArchive' : ' Archive'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
        alignment: Alignment.centerRight,
      ),
    );
  }

  Widget slideRightBackground(Chat chat) {
    return Container(
      color: SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.pin
          ? Colors.yellow[800]
          : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.alerts
              ? Colors.purple
              : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.delete
                  ? Colors.red
                  : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.mark_read
                      ? Colors.blue
                      : Colors.red,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 20,
            ),
            Icon(
              SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.pin
                  ? (chat.isPinned! ? Icons.star_outline : Icons.star)
                  : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.alerts
                      ? (chat.muteType == "mute" ? Icons.notifications_active : Icons.notifications_off)
                      : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.delete
                          ? Icons.delete_forever
                          : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.mark_read
                              ? (chat.hasUnreadMessage! ? Icons.mark_chat_read : Icons.mark_chat_unread)
                              : (chat.isArchived! ? Icons.unarchive : Icons.archive),
              color: Colors.white,
            ),
            Text(
              SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.pin
                  ? (chat.isPinned! ? " Unpin" : " Pin")
                  : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.alerts
                      ? (chat.muteType == "mute" ? ' Show Alerts' : ' Hide Alerts')
                      : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.delete
                          ? " Delete"
                          : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.mark_read
                              ? (chat.hasUnreadMessage! ? ' Mark Read' : ' Mark Unread')
                              : (chat.isArchived! ? ' UnArchive' : ' Archive'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Future<void> openLastChat(BuildContext context) async {
    if (ChatBloc().chatRequest != null &&
        prefs.getString('lastOpenedChat') != null &&
        (!context.isPhone || context.isLandscape) &&
        SettingsManager().settings.tabletMode.value &&
        ChatManager().activeChat?.chat.guid != prefs.getString('lastOpenedChat') &&
        !LifeCycleManager().isBubble) {
      await ChatBloc().chatRequest!.future;
      CustomNavigator.pushAndRemoveUntil(
        context,
        ConversationView(
            chat: kIsWeb
                ? await Chat.findOneWeb(guid: prefs.getString('lastOpenedChat'))
                : Chat.findOne(guid: prefs.getString('lastOpenedChat'))),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!openedChatAlready) {
      Future.delayed(Duration.zero, () => openLastChat(context));
      openedChatAlready = true;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: SettingsManager().settings.immersiveMode.value ? Colors.transparent : context.theme.colorScheme.background, // navigation bar color
        systemNavigationBarIconBrightness: context.theme.colorScheme.brightness,
        statusBarColor: Colors.transparent, // status bar color
        statusBarIconBrightness: context.theme.colorScheme.brightness.opposite,
      ),
      child: Obx(() => buildForDevice()),
    );
  }

  Widget _extendedTitle(Animation<double> animation) {
    bool showArchived = widget.parent.widget.showArchivedChats;
    bool showUnknown = widget.parent.widget.showUnknownSenders;
    return FadeTransition(
      opacity: Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: animation,
        curve: Interval(0.3, 1.0, curve: Curves.easeIn),
      )),
      child: Center(child: Obx(() {
        int unreads = ChatBloc().unreads.value;
        return Text(
            selected.isNotEmpty
                ? "${selected.length} selected"
                : showArchived ? "Archived" : showUnknown ? "Unknown Senders" : unreads > 0
                    ? "$unreads unread message${unreads > 1 ? "s" : ""}"
                    : "Messages",
            style: context.theme.textTheme.displaySmall!.copyWith(color: context.theme.colorScheme.onBackground));
      })),
    );
  }

  Widget _collapsedTitle(Animation<double> animation) {
    bool showArchived = widget.parent.widget.showArchivedChats;
    bool showUnknown = widget.parent.widget.showUnknownSenders;
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
        parent: animation,
        curve: Interval(0.0, 0.7, curve: Curves.easeOut),
      )),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: EdgeInsets.only(left: showArchived || showUnknown ? 60 : 16),
          height: (kToolbarHeight + (kIsDesktop ? 20 : 0)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                widget.parent.getHeaderTextWidget(size: 20),
                widget.parent.getConnectionIndicatorWidget(),
                widget.parent.getSyncIndicatorWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    bool showArchived = widget.parent.widget.showArchivedChats;
    bool showUnknown = widget.parent.widget.showUnknownSenders;
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        height: (kToolbarHeight + (kIsDesktop ? 20 : 0)),
        child: Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showArchived || showUnknown)
                    IconButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                      padding: EdgeInsets.zero,
                      icon: buildBackButton(context)
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  (!showArchived && !showUnknown)
                      ? IconButton(
                    onPressed: () async {
                      CustomNavigator.pushLeft(
                        context,
                        SearchView(),
                      );
                    },
                    icon: Icon(
                      Icons.search,
                      color: context.theme.colorScheme.properOnSurface,
                    ),
                  ) : SizedBox.shrink(),
                  (SettingsManager().settings.moveChatCreatorToHeader.value &&
                      !showArchived &&
                      !showUnknown)
                      ? GestureDetector(
                    onLongPress: SettingsManager().settings.cameraFAB.value ? () async {
                      bool camera = await Permission.camera.isGranted;
                      if (!camera) {
                        bool granted = (await Permission.camera.request()) ==
                            PermissionStatus.granted;
                        if (!granted) {
                          showSnackbar("Error", "Camera was denied");
                          return;
                        }
                      }

                      final XFile? file = await ImagePicker().pickImage(source: ImageSource.camera);
                      if (file != null) {
                        widget.parent.openNewChatCreator(existing: [PlatformFile(
                          path: file.path,
                          name: file.path.split('/').last,
                          size: await file.length(),
                          bytes: await file.readAsBytes(),
                        )]);
                      }
                    } : null,
                    child: IconButton(
                      onPressed: () {
                        EventDispatcher().emit("update-highlight", null);
                        CustomNavigator.pushAndRemoveUntil(
                          context,
                          ConversationView(
                            isCreator: true,
                          ),
                              (route) => route.isFirst,
                        );
                      },
                      icon: Icon(
                        Icons.create_outlined,
                        color: context.theme.colorScheme.properOnSurface,
                      ),
                    ),
                  )
                      : Container(),
                  Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Container(
                      width: 40,
                      child: widget.parent.buildSettingsButton(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateExpandRatio(BoxConstraints constraints, BuildContext context) {
    var expandRatio = (constraints.maxHeight - (kToolbarHeight + (kIsDesktop ? 20 : 0))) / (context.height / 3 - (kToolbarHeight + (kIsDesktop ? 20 : 0)));

    if (expandRatio > 1.0) expandRatio = 1.0;
    if (expandRatio < 0.0) expandRatio = 0.0;

    return expandRatio;
  }

  Widget buildChatList() {
    bool showArchived = widget.parent.widget.showArchivedChats;
    bool showUnknown = widget.parent.widget.showUnknownSenders;
    Color headerColor = ThemeManager().inDarkMode(context)
        ? context.theme.colorScheme.background : context.theme.colorScheme.properSurface;
    Color tileColor = ThemeManager().inDarkMode(context)
        ? context.theme.colorScheme.properSurface : context.theme.colorScheme.background;

    final Rx<Color> _headerColor = (SettingsManager().settings.windowEffect.value == WindowEffect.disabled
        ? headerColor
        : Colors.transparent)
        .obs;

    final Rx<Color> _tileColor = (SettingsManager().settings.windowEffect.value == WindowEffect.disabled
        ? tileColor
        : Colors.transparent)
        .obs;

    return WillPopScope(
      onWillPop: () async {
        if (selected.isNotEmpty) {
          selected = [];
          setState(() {});
          return false;
        }
        return true;
      },
      child: Obx(() => Scaffold(
        backgroundColor: _headerColor.value,
        body: SafeArea(
          child: NotificationListener<ScrollEndNotification>(
            onNotification: (_) {
              final scrollDistance = context.height / 3 - 57;

              if (scrollController.offset > 0 && scrollController.offset < scrollDistance) {
                final double snapOffset = scrollController.offset / scrollDistance > 0.5 ? scrollDistance : 0;

                Future.microtask(() => scrollController.animateTo(snapOffset,
                    duration: Duration(milliseconds: 200), curve: Curves.linear));
              }
              return false;
            },
            child: ScrollbarWrapper(
              showScrollbar: true,
              controller: scrollController,
              child: Obx(
                () => CustomScrollView(
                  physics: (SettingsManager().settings.betterScrolling.value && (kIsDesktop || kIsWeb))
                      ? NeverScrollableScrollPhysics()
                      : ThemeSwitcher.getScrollPhysics(),
                  controller: scrollController,
                  slivers: [
                    SliverAppBar(
                      backgroundColor: _headerColor.value,
                      shadowColor: Colors.black,
                      pinned: true,
                      stretch: true,
                      expandedHeight: context.height / 3,
                      toolbarHeight: kToolbarHeight + (kIsDesktop ? 20 : 0),
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          final expandRatio = _calculateExpandRatio(constraints, context);
                          final animation = AlwaysStoppedAnimation(expandRatio);

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              _extendedTitle(animation),
                              _collapsedTitle(animation),
                              _actions(),
                            ],
                          );
                        },
                      ),
                    ),
                    if (hasPinnedChat())
                      SliverList(
                          delegate: SliverChildListDelegate([
                        SingleChildScrollView(
                          child: Obx(
                            () {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: _tileColor.value,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final chat = ChatBloc()
                                        .chats
                                        .archivedHelper(showArchived)
                                        .unknownSendersHelper(showUnknown)
                                        .bigPinHelper(true)[index];
                                    return buildChatItem(chat);
                                  },
                                  itemCount: ChatBloc()
                                      .chats
                                      .archivedHelper(showArchived)
                                      .unknownSendersHelper(showUnknown)
                                      .bigPinHelper(true)
                                      .length,
                                ),
                              );
                            },
                          ),
                        )
                      ])),
                    if (hasPinnedChat()) SliverToBoxAdapter(child: SizedBox(height: 15)),
                    SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          SingleChildScrollView(
                            child: Obx(
                              () {
                                if (!ChatBloc().loadedChatBatch.value) {
                                  return Center(
                                    child: Container(
                                      padding: EdgeInsets.only(top: kToolbarHeight + (kIsDesktop ? 20 : 0)),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "Loading chats...",
                                              style: Theme.of(context).textTheme.labelLarge,
                                            ),
                                          ),
                                          buildProgressIndicator(context, size: 15),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                if (ChatBloc().loadedChatBatch.value &&
                                    ChatBloc()
                                        .chats
                                        .archivedHelper(showArchived)
                                        .unknownSendersHelper(showUnknown)
                                        .isEmpty) {
                                  return Center(
                                    child: Container(
                                      padding: EdgeInsets.only(top: kToolbarHeight + (kIsDesktop ? 20 : 0)),
                                      child: Text(
                                        "You have no archived chats",
                                        style: context.textTheme.labelLarge,
                                      ),
                                    ),
                                  );
                                }
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    color: _tileColor.value,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final chat = ChatBloc()
                                          .chats
                                          .archivedHelper(showArchived)
                                          .unknownSendersHelper(showUnknown)
                                          .bigPinHelper(false)[index];
                                      return buildChatItem(chat);
                                    },
                                    itemCount: ChatBloc()
                                        .chats
                                        .archivedHelper(showArchived)
                                        .unknownSendersHelper(showUnknown)
                                        .bigPinHelper(false)
                                        .length,
                                  ),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(child: Obx(() => SizedBox(height: 100 + remainingHeight.value))),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: AnimatedSize(
          duration: Duration(milliseconds: 200),
          child: selected.isEmpty
              ? null
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (([0, selected.length])
                        .contains(selected.where((element) => element.hasUnreadMessage!).length))
                      IconButton(
                        onPressed: () {
                          for (Chat element in selected) {
                            element.toggleHasUnread(!element.hasUnreadMessage!);
                          }
                          selected = [];
                          if (mounted) setState(() {});
                        },
                        icon: Icon(
                          selected[0].hasUnreadMessage!
                              ? Icons.mark_chat_read_outlined
                              : Icons.mark_chat_unread_outlined,
                          color: context.theme.colorScheme.primary,
                        ),
                      ),
                    if (([0, selected.length])
                        .contains(selected.where((element) => element.muteType == "mute").length))
                      IconButton(
                        onPressed: () {
                          for (Chat element in selected) {
                            element.toggleMute(element.muteType != "mute");
                          }
                          selected = [];
                          if (mounted) setState(() {});
                        },
                        icon: Icon(
                          selected[0].muteType == "mute"
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          color: context.theme.colorScheme.primary,
                        ),
                      ),
                    if (([0, selected.length])
                        .contains(selected.where((element) => element.isPinned!).length))
                      IconButton(
                        onPressed: () {
                          for (Chat element in selected) {
                            element.togglePin(!element.isPinned!);
                          }
                          selected = [];
                          if (mounted) setState(() {});
                        },
                        icon: Icon(
                          selected[0].isPinned! ? Icons.push_pin_outlined : Icons.push_pin,
                          color: context.theme.colorScheme.primary,
                        ),
                      ),
                    IconButton(
                      onPressed: () {
                        for (Chat element in selected) {
                          if (element.isArchived!) {
                            ChatBloc().unArchiveChat(element);
                          } else {
                            ChatBloc().archiveChat(element);
                          }
                        }
                        selected = [];
                        if (mounted) setState(() {});
                      },
                      icon: Icon(
                        showArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        for (Chat element in selected) {
                          ChatBloc().deleteChat(element);
                          Chat.deleteChat(element);
                        }
                        selected = [];
                        if (mounted) setState(() {});
                      },
                      icon: Icon(
                        Icons.delete_outlined,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: selected.isEmpty && !SettingsManager().settings.moveChatCreatorToHeader.value
            ? widget.parent.buildFloatingActionButton()
            : null,
      )),
    );
  }

  Widget buildForLandscape(BuildContext context, Widget chatList) {
    return VerticalSplitView(
      initialRatio: 0.4,
      minRatio: kIsDesktop || kIsWeb ? 0.2 : 0.33,
      maxRatio: 0.5,
      allowResize: true,
      left: LayoutBuilder(builder: (context, constraints) {
        CustomNavigator.maxWidthLeft = constraints.maxWidth;
        return WillPopScope(
          onWillPop: () async {
            Get.until((route) {
              bool id2result = false;
              // check if we should pop the left side first
              Get.until((route) {
                if (route.settings.name != "initial") {
                  Get.back(id: 2);
                  id2result = true;
                }
                return true;
              }, id: 2);
              if (!id2result) {
                if (route.settings.name == "initial") {
                  SystemNavigator.pop();
                } else {
                  Get.back(id: 1);
                }
              }
              return true;
            }, id: 1);
            return false;
          },
          child: Navigator(
            key: Get.nestedKey(1),
            onPopPage: (route, _) {
              return false;
            },
            pages: [CupertinoPage(name: "initial", child: chatList)],
          ),
        );
      }),
      right: LayoutBuilder(builder: (context, constraints) {
        CustomNavigator.maxWidthRight = constraints.maxWidth;
        return WillPopScope(
          onWillPop: () async {
            Get.back(id: 2);
            return false;
          },
          child: Navigator(
            key: Get.nestedKey(2),
            onPopPage: (route, _) {
              return false;
            },
            pages: [
              CupertinoPage(
                  name: "initial",
                  child: Scaffold(
                    backgroundColor: context.theme.backgroundColor,
                    extendBodyBehindAppBar: true,
                    body: Center(
                      child: Container(
                          child: Text("Select a chat from the list",
                              style: context.theme.textTheme.bodyLarge)),
                    ),
                  ))
            ],
          ),
        );
      }),
    );
  }

  Widget buildForDevice() {
    bool showAltLayout =
        SettingsManager().settings.tabletMode.value && (!context.isPhone || context.isLandscape) && context.width > 600 && !LifeCycleManager().isBubble;
    Widget chatList = buildChatList();
    if (showAltLayout && !widget.parent.widget.showUnknownSenders && !widget.parent.widget.showArchivedChats) {
      return buildForLandscape(context, chatList);
    } else if (!widget.parent.widget.showArchivedChats && !widget.parent.widget.showUnknownSenders) {
      return TitleBarWrapper(child: chatList);
    }

    return chatList;
  }

  Widget buildChatItem(Chat chat) {
    bool showArchived = widget.parent.widget.showArchivedChats;
    return Obx(() {
      if (SettingsManager().settings.swipableConversationTiles.value) {
        return Dismissible(
            background: (kIsDesktop || kIsWeb) ? null : Obx(() => slideRightBackground(chat)),
            secondaryBackground: (kIsDesktop || kIsWeb) ? null : Obx(() => slideLeftBackground(chat)),
            // Each Dismissible must contain a Key. Keys allow Flutter to
            // uniquely identify widgets.
            key: UniqueKey(),
            // Provide a function that tells the app
            // what to do after an item has been swiped away.
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                if (SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.pin) {
                  chat.togglePin(!chat.isPinned!);
                  EventDispatcher().emit("refresh", null);
                  if (mounted) setState(() {});
                } else if (SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.alerts) {
                  chat.toggleMute(chat.muteType != "mute");
                  if (mounted) setState(() {});
                } else if (SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.delete) {
                  ChatBloc().deleteChat(chat);
                  Chat.deleteChat(chat);
                } else if (SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.mark_read) {
                  ChatBloc().toggleChatUnread(chat, !chat.hasUnreadMessage!);
                } else {
                  if (chat.isArchived!) {
                    ChatBloc().unArchiveChat(chat);
                  } else {
                    ChatBloc().archiveChat(chat);
                  }
                }
              } else {
                if (SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.pin) {
                  chat.togglePin(!chat.isPinned!);
                  EventDispatcher().emit("refresh", null);
                  if (mounted) setState(() {});
                } else if (SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.alerts) {
                  chat.toggleMute(chat.muteType != "mute");
                  if (mounted) setState(() {});
                } else if (SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.delete) {
                  ChatBloc().deleteChat(chat);
                  Chat.deleteChat(chat);
                } else if (SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.mark_read) {
                  ChatBloc().toggleChatUnread(chat, !chat.hasUnreadMessage!);
                } else {
                  if (chat.isArchived!) {
                    ChatBloc().unArchiveChat(chat);
                  } else {
                    ChatBloc().archiveChat(chat);
                  }
                }
              }
            },
            child: (!showArchived && chat.isArchived!)
                ? Container()
                : (showArchived && !chat.isArchived!)
                    ? Container()
                    : ConversationTile(
                        key: UniqueKey(),
                        chat: chat,
                        inSelectMode: selected.isNotEmpty,
                        selected: selected,
                        onSelect: (bool selected) {
                          if (selected) {
                            this.selected.add(chat);
                            setState(() {});
                          } else {
                            this.selected.removeWhere((element) => element.guid == chat.guid);
                            setState(() {});
                          }
                        },
                      ));
      } else {
        return ConversationTile(
          key: UniqueKey(),
          chat: chat,
          inSelectMode: selected.isNotEmpty,
          selected: selected,
          onSelect: (bool selected) {
            if (selected) {
              this.selected.add(chat);
              setState(() {});
            } else {
              this.selected.removeWhere((element) => element.guid == chat.guid);
              setState(() {});
            }
          },
        );
      }
    });
  }
}
