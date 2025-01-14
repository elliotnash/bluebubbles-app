import 'dart:async';

import 'package:bluebubbles/helpers/constants.dart';
import 'package:bluebubbles/helpers/themes.dart';
import 'package:bluebubbles/helpers/utils.dart';
import 'package:bluebubbles/main.dart';
import 'package:bluebubbles/managers/firebase/fcm_manager.dart';
import 'package:bluebubbles/repository/database.dart';
import 'package:bluebubbles/repository/models/models.dart';
import 'package:bluebubbles/repository/models/settings.dart';
import 'package:bluebubbles/socket_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_io/io.dart';
import 'package:version/version.dart';

/// [SettingsManager] is responsible for making the current settings accessible to other managers and for saving new settings
///
/// The class also holds miscelaneous stuff such as the [appDocDir] which is used a lot throughout the app
/// This class is a singleton
class SettingsManager {
  factory SettingsManager() {
    return _manager;
  }

  static final SettingsManager _manager = SettingsManager._internal();

  SettingsManager._internal();

  /// [appDocDir] is just a directory that is commonly used
  /// It cannot be accessed by the user, and is private to the app
  late Directory appDocDir;

  /// [settings] is just an instance of the current settings that are saved
  late Settings settings;
  FCMData? fcmData;
  String? countryCode;
  String? _serverVersion;
  bool canAuthenticate = false;

  int get compressionQuality {
    if (settings.lowMemoryMode.value) {
      return 10;
    }

    return SettingsManager().settings.previewCompressionQuality.value;
  }

  /// [init] is run at start and fetches both the [appDocDir] and sets the [settings] to a default value
  Future<void> init() async {
    settings = Settings();
    if (!kIsWeb) {
      //ignore: unnecessary_cast, we need this as a workaround
      appDocDir = (await getApplicationSupportDirectory()) as Directory;
      bool? useCustomPath = prefs.getBool("use-custom-path");
      String? customStorePath = prefs.getString("custom-path");
      if (useCustomPath == true) {
        //ignore: unnecessary_cast, we need this as a workaround
        appDocDir = customStorePath == null ? (await getApplicationDocumentsDirectory() as Directory) : Directory(customStorePath);
      }
    }
    try {
      canAuthenticate = !kIsWeb && !kIsDesktop && await LocalAuthentication().isDeviceSupported();
    } catch (_) {
      canAuthenticate = false;
    }
  }

  /// Retreives files from disk and stores them in [settings]
  ///
  ///
  /// @param [headless] determines whether the socket will be started automatically and fcm will be initialized.
  ///
  /// @param [context] is an optional parameter to be used for setting the adaptive theme based on the settings.
  /// Setting to null will prevent the theme from being set and will be set to null in the background isolate
  Future<void> getSavedSettings({bool headless = false}) async {
    settings = Settings.getSettings();

    fcmData = FCMData.getFCM();
    if (headless) return;

    try {
      // Set the [displayMode] to that saved in settings
      if (!kIsWeb && !kIsDesktop) {
        FlutterDisplayMode.setPreferredMode(await settings.getDisplayMode());
      }
    } catch (_) {}

    // Change the [finishedSetup] status to that of the settings
    if (!settings.finishedSetup.value) {
      DBProvider.deleteDB();
    }

    // If we aren't running in the background, then we should auto start the socket and authorize fcm just in case we haven't
    if (!headless) {
      try {
        if (settings.finishedSetup.value) {
          SocketManager().startSocketIO();
          fcm.registerDevice();
        }
      } catch (_) {}
    }
  }

  /// Saves a [Settings] instance to disk
  Future<void> saveSettings([Settings? newSettings]) async {
    // Set the new settings as the current settings in the manager
    settings = newSettings ?? settings;
    settings.save();
    try {
      // Set the [displayMode] to that saved in settings
      if (!kIsWeb && !kIsDesktop) {
        FlutterDisplayMode.setPreferredMode(await settings.getDisplayMode());
      }
    } catch (_) {}
  }

  /// Updates the selected theme for the app
  ///
  /// @param [selectedLightTheme] is the [ThemeObject] of the light theme to save and set as light theme in the db
  ///
  /// @param [selectedDarkTheme] is the [ThemeObject] of the dark theme to save and set as dark theme in the db
  ///
  /// @param [context] is the [BuildContext] used to set the theme of the new settings
  void saveSelectedTheme(
    BuildContext context, {
    ThemeStruct? selectedLightTheme,
    ThemeStruct? selectedDarkTheme,
  }) {
    selectedLightTheme?.save();
    selectedDarkTheme?.save();
    if (selectedLightTheme != null) prefs.setString("selected-light", selectedLightTheme.name);
    if (selectedDarkTheme != null) prefs.setString("selected-dark", selectedDarkTheme.name);

    loadTheme(context);
  }

  /// Updates FCM data and saves to disk. It will also run [registerFcmDevice] automatically
  ///
  /// @param [data] is the [FCMData] to save
  void saveFCMData(FCMData data) {
    fcmData = data;
    fcmData!.save();
    fcm.registerDevice();
  }

  Future<void> resetConnection() async {
    if (SocketManager().socket != null && SocketManager().socket!.connected) {
      SocketManager().socket!.disconnect();
    }

    Settings temp = settings;
    temp.finishedSetup.value = false;
    temp.guidAuthKey.value = "";
    temp.serverAddress.value = "";
    temp.lastIncrementalSync.value = 0;
    await saveSettings(temp);
  }

  Future<Tuple2<int?, int?>?> getMacOSVersion({bool refresh = false}) async {
    if (refresh) {
      final response = await api.serverInfo();
      if (response.statusCode == 200) {
        final version = int.tryParse(response.data['data']['os_version'].split(".")[0]);
        final minorVersion = int.tryParse(response.data['data']['os_version'].split(".")[1]);
        _serverVersion = response.data['data']['server_version'];
        if (version != null) prefs.setInt("macos-version", version);
        if (minorVersion != null) prefs.setInt("macos-minor-version", minorVersion);
        return Tuple2(version, minorVersion);
      } else {
        return null;
      }
    } else {
      return Tuple2(prefs.getInt("macos-version") ?? 11, prefs.getInt("macos-minor-version") ?? 0);
    }
  }

  Future<bool> get isMinSierra async {
    final val = await getMacOSVersion();
    return (val?.item1 ?? 0) > 10 || ((val?.item1 ?? 0) == 10 && (val?.item2 ?? 0) > 11);
  }

  Future<bool> get isMinBigSur async {
    final val = await getMacOSVersion();
    return (val?.item1 ?? 0) >= 11;
  }

  FutureOr<String?> getServerVersion() async {
    if (_serverVersion == null) {
      final response = await api.serverInfo();
      if (response.statusCode == 200) {
        _serverVersion = response.data['data']['server_version'];
      }
    }
    return _serverVersion;
  }

  Future<int> getServerVersionCode() async {
    final version = await getServerVersion();
    Version code = Version.parse(version!);
    return code.major * 100 + code.minor * 21 + code.patch;
  }

  bool get isFullMonet => SettingsManager().settings.monetTheming.value == Monet.full;
}
