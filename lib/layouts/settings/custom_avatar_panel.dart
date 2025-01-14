import 'package:bluebubbles/blocs/chat_bloc.dart';
import 'package:bluebubbles/helpers/constants.dart';
import 'package:bluebubbles/helpers/hex_color.dart';
import 'package:bluebubbles/helpers/navigator.dart';
import 'package:bluebubbles/helpers/ui_helpers.dart';
import 'package:bluebubbles/layouts/conversation_list/conversation_tile.dart';
import 'package:bluebubbles/layouts/settings/settings_widgets.dart';
import 'package:bluebubbles/layouts/widgets/avatar_crop.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/managers/theme_manager.dart';
import 'package:bluebubbles/repository/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_io/io.dart';

class CustomAvatarPanelController extends GetxController {
  late Settings _settingsCopy;

  @override
  void onInit() {
    super.onInit();
    _settingsCopy = SettingsManager().settings;
  }

  @override
  void dispose() {
    SettingsManager().saveSettings(_settingsCopy);
    super.dispose();
  }
}

class CustomAvatarPanel extends StatelessWidget {
  final controller = Get.put(CustomAvatarPanelController());
  @override
  Widget build(BuildContext context) {
    // Samsung theme should always use the background color as the "header" color
    Color headerColor = ThemeManager().inDarkMode(context)
        ? context.theme.colorScheme.background : context.theme.colorScheme.properSurface;
    Color tileColor = ThemeManager().inDarkMode(context)
        ? context.theme.colorScheme.properSurface : context.theme.colorScheme.background;
    
    // reverse material color mapping to be more accurate
    if (SettingsManager().settings.skin.value == Skins.Material && ThemeManager().inDarkMode(context)) {
      final temp = headerColor;
      headerColor = tileColor;
      tileColor = temp;
    }

    return SettingsScaffold(
      title: "Custom Avatars",
      initialHeader: null,
      iosSubtitle: null,
      materialSubtitle: null,
      tileColor: tileColor,
      headerColor: headerColor,
      bodySlivers: [
        Obx(() {
          if (!ChatBloc().loadedChatBatch.value) {
            return SliverToBoxAdapter(
              child: Center(
                child: Container(
                  padding: EdgeInsets.only(top: 50.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Loading chats...",
                          style: context.theme.textTheme.labelLarge,
                        ),
                      ),
                      buildProgressIndicator(context, size: 15),
                    ],
                  ),
                ),
              ),
            );
          }
          if (ChatBloc().loadedChatBatch.value && ChatBloc().chats.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: Container(
                  padding: EdgeInsets.only(top: 50.0),
                  child: Text(
                    "You have no chats :(",
                    style: context.theme.textTheme.labelLarge,
                  ),
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return ConversationTile(
                  key: Key(
                      ChatBloc().chats[index].guid.toString()),
                  chat: ChatBloc().chats[index],
                  inSelectMode: true,
                  onSelect: (_) {
                    if (ChatBloc().chats[index].customAvatarPath != null) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                              backgroundColor: context.theme.colorScheme.properSurface,
                              title: Text("Custom Avatar",
                                  style: context.theme.textTheme.titleLarge),
                              content: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "You have already set a custom avatar for this chat. What would you like to do?",
                                      style: context.theme.textTheme.bodyLarge),
                                ],
                              ),
                              actions: <Widget>[
                                TextButton(
                                    child: Text("Cancel", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    }),
                                TextButton(
                                    child: Text("Reset", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                                    onPressed: () {
                                      File file = File(ChatBloc().chats[index].customAvatarPath!);
                                      file.delete();
                                      ChatBloc().chats[index].customAvatarPath = null;
                                      ChatBloc().chats[index].save(updateCustomAvatarPath: true);
                                      Get.back();
                                    }),
                                TextButton(
                                    child: Text("Set New", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      CustomNavigator.pushSettings(
                                        context,
                                        AvatarCrop(index: index),
                                      );
                                    }),
                              ]);
                        },
                      );
                    } else {
                      CustomNavigator.pushSettings(
                        context,
                        AvatarCrop(index: index),
                      );
                    }
                  },
                );
              },
              childCount: ChatBloc().chats.length,
            ),
          );
        }),
      ]
    );
  }
}
