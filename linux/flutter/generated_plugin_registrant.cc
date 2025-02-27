//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <ambient_light/ambient_light_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) ambient_light_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AmbientLightPlugin");
  ambient_light_plugin_register_with_registrar(ambient_light_registrar);
}
