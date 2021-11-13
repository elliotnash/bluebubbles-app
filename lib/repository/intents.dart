import 'package:bluebubbles/action_handler.dart';
import 'package:bluebubbles/blocs/chat_bloc.dart';
import 'package:bluebubbles/blocs/message_bloc.dart';
import 'package:bluebubbles/helpers/navigator.dart';
import 'package:bluebubbles/layouts/conversation_details/conversation_details.dart';
import 'package:bluebubbles/layouts/conversation_view/conversation_view.dart';
import 'package:bluebubbles/layouts/search/search_view.dart';
import 'package:bluebubbles/layouts/settings/settings_panel.dart';
import 'package:bluebubbles/layouts/widgets/theme_switcher/theme_switcher.dart';
import 'package:bluebubbles/managers/current_chat.dart';
import 'package:bluebubbles/managers/event_dispatcher.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/repository/models/models.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class OpenSettingsAction extends Action<OpenSettingsIntent> {
  OpenSettingsAction(this.context);

  final BuildContext context;

  @override
  Object? invoke(covariant OpenSettingsIntent intent) {
    Navigator.of(context).push(
      ThemeSwitcher.buildPageRoute(
        builder: (BuildContext context) {
          return SettingsPanel();
        },
      ),
    );
  }
}

class OpenNewChatCreatorIntent extends Intent {
  const OpenNewChatCreatorIntent();
}

class OpenNewChatCreatorAction extends Action<OpenNewChatCreatorIntent> {
  OpenNewChatCreatorAction(this.context);

  final BuildContext context;

  @override
  Object? invoke(covariant OpenNewChatCreatorIntent intent) {
    EventDispatcher().emit("update-highlight", null);
    CustomNavigator.pushAndRemoveUntil(
      context,
      ConversationView(
        isCreator: true,
      ),
      (route) => route.isFirst,
    );
  }
}

class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

class OpenSearchAction extends Action<OpenSearchIntent> {
  OpenSearchAction(this.context);

  final BuildContext context;

  @override
  Object? invoke(covariant OpenSearchIntent intent) async {
    CustomNavigator.pushLeft(
      context,
      SearchView(),
    );
  }
}

class ReplyRecentIntent extends Intent {
  const ReplyRecentIntent();
}

class ReplyRecentAction extends Action<ReplyRecentIntent> {
  ReplyRecentAction(this.bloc);

  final MessageBloc bloc;

  @override
  Object? invoke(covariant ReplyRecentIntent intent) async {
    final message = bloc.messages.values.firstWhereOrNull((element) => element.associatedMessageGuid == null);
    if (message != null && SettingsManager().settings.enablePrivateAPI.value) {
      EventDispatcher().emit("focus-keyboard", message);
    }
  }
}

class HeartRecentIntent extends Intent {
  const HeartRecentIntent();
}

class HeartRecentAction extends Action<HeartRecentIntent> {
  HeartRecentAction(this.bloc, this.chat);

  final MessageBloc bloc;
  final Chat chat;

  @override
  Object? invoke(covariant HeartRecentIntent intent) async {
    final message = bloc.messages.values.firstWhereOrNull((element) => element.associatedMessageGuid == null);
    if (message != null && SettingsManager().settings.enablePrivateAPI.value) {
      ActionHandler.sendReaction(chat, message, "love");
    }
  }
}

class LikeRecentIntent extends Intent {
  const LikeRecentIntent();
}

class LikeRecentAction extends Action<LikeRecentIntent> {
  LikeRecentAction(this.bloc, this.chat);

  final MessageBloc bloc;
  final Chat chat;

  @override
  Object? invoke(covariant LikeRecentIntent intent) async {
    final message = bloc.messages.values.firstWhereOrNull((element) => element.associatedMessageGuid == null);
    if (message != null && SettingsManager().settings.enablePrivateAPI.value) {
      ActionHandler.sendReaction(chat, message, "like");
    }
  }
}

class DislikeRecentIntent extends Intent {
  const DislikeRecentIntent();
}

class DislikeRecentAction extends Action<DislikeRecentIntent> {
  DislikeRecentAction(this.bloc, this.chat);

  final MessageBloc bloc;
  final Chat chat;

  @override
  Object? invoke(covariant DislikeRecentIntent intent) async {
    final message = bloc.messages.values.firstWhereOrNull((element) => element.associatedMessageGuid == null);
    if (message != null && SettingsManager().settings.enablePrivateAPI.value) {
      ActionHandler.sendReaction(chat, message, "dislike");
    }
  }
}

class LaughRecentIntent extends Intent {
  const LaughRecentIntent();
}

class LaughRecentAction extends Action<LaughRecentIntent> {
  LaughRecentAction(this.bloc, this.chat);

  final MessageBloc bloc;
  final Chat chat;

  @override
  Object? invoke(covariant LaughRecentIntent intent) async {
    final message = bloc.messages.values.firstWhereOrNull((element) => element.associatedMessageGuid == null);
    if (message != null && SettingsManager().settings.enablePrivateAPI.value) {
      ActionHandler.sendReaction(chat, message, "laugh");
    }
  }
}

class EmphasizeRecentIntent extends Intent {
  const EmphasizeRecentIntent();
}

class EmphasizeRecentAction extends Action<EmphasizeRecentIntent> {
  EmphasizeRecentAction(this.bloc, this.chat);

  final MessageBloc bloc;
  final Chat chat;

  @override
  Object? invoke(covariant EmphasizeRecentIntent intent) async {
    final message = bloc.messages.values.firstWhereOrNull((element) => element.associatedMessageGuid == null);
    if (message != null && SettingsManager().settings.enablePrivateAPI.value) {
      ActionHandler.sendReaction(chat, message, "emphasize");
    }
  }
}

class QuestionRecentIntent extends Intent {
  const QuestionRecentIntent();
}

class QuestionRecentAction extends Action<QuestionRecentIntent> {
  QuestionRecentAction(this.bloc, this.chat);

  final MessageBloc bloc;
  final Chat chat;

  @override
  Object? invoke(covariant QuestionRecentIntent intent) async {
    final message = bloc.messages.values.firstWhereOrNull((element) => element.associatedMessageGuid == null);
    if (message != null && SettingsManager().settings.enablePrivateAPI.value) {
      ActionHandler.sendReaction(chat, message, "question");
    }
  }
}

class OpenNextChatIntent extends Intent {
  const OpenNextChatIntent();
}

class OpenNextChatAction extends Action<OpenNextChatIntent> {
  OpenNextChatAction(this.context);

  final BuildContext context;

  @override
  Object? invoke(covariant OpenNextChatIntent intent) {
    final chat = CurrentChat.activeChat?.chat;
    if (chat != null) {
      final index = ChatBloc().chats.indexWhere((e) => e.guid == chat.guid);
      if (index > -1 && index < ChatBloc().chats.length) {
        CustomNavigator.pushAndRemoveUntil(
          context,
          ConversationView(
            chat: ChatBloc().chats[index + 1],
          ),
          (route) => route.isFirst,
        );
      }
    }
  }
}

class OpenPreviousChatIntent extends Intent {
  const OpenPreviousChatIntent();
}

class OpenPreviousChatAction extends Action<OpenPreviousChatIntent> {
  OpenPreviousChatAction(this.context);

  final BuildContext context;

  @override
  Object? invoke(covariant OpenPreviousChatIntent intent) {
    final chat = CurrentChat.activeChat?.chat;
    if (chat != null) {
      final index = ChatBloc().chats.indexWhere((e) => e.guid == chat.guid);
      if (index > 0 && index < ChatBloc().chats.length) {
        CustomNavigator.pushAndRemoveUntil(
          context,
          ConversationView(
            chat: ChatBloc().chats[index - 1],
          ),
          (route) => route.isFirst,
        );
      }
    }
  }
}

class OpenChatDetailsIntent extends Intent {
  const OpenChatDetailsIntent();
}

class OpenChatDetailsAction extends Action<OpenChatDetailsIntent> {
  OpenChatDetailsAction(this.context, this.bloc, this.chat);

  final BuildContext context;
  final MessageBloc bloc;
  final Chat chat;

  @override
  Object? invoke(covariant OpenChatDetailsIntent intent) {
    CustomNavigator.push(
      context,
      ConversationDetails(messageBloc: bloc, chat: chat),
    );
  }
}