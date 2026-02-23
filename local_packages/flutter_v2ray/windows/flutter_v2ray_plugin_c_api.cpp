#include "include/flutter_v2ray/flutter_v2ray_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_v2ray_plugin.h"

void FlutterV2rayPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_v2ray::FlutterV2rayPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
