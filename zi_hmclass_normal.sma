#include <amxmodx>
#include <amxmisc>
#include <zi_core>

#define PLUGIN "[MG][ZI] ZM Class Normal"
#define VERSION "1.0.0"
#define AUTHOR "Vieni"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    zi_core_class_human_reg(ZI_HMCLASS_NORMAL, "asdasd", "asdasd", "sas", 0)
}