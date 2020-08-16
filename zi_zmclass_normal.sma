#include <amxmodx>
#include <amxmisc>
#include <zi_core>

#define PLUGIN "[MG][ZI] ZM Class Normal"
#define VERSION "1.0.0"
#define AUTHOR "Vieni"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    zi_core_class_zombie_reg(ZI_ZMCLASS_NORMAL, ZI_ZMSUBCLASS_NORMAL1, "asd", "asd", "gign")
    zi_core_class_zombiesub_reg(ZI_ZMCLASS_NORMAL, ZI_ZMSUBCLASS_NORMAL1, "asd", "asd", "models/v_ak47.mdl", "gign", 1, 500, 400.0, 1.2)
}