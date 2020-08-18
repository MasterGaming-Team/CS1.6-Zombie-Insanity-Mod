#include <amxmodx>
#include <amxconst>
#include <mg_missions_api>

#define PLUGIN "[MG] Missions Surface"
#define VERSION "1.0.0"
#define AUTHOR "Vieni"

#define MENUMISSIONS_IPP    5

new Array:arrayMissionId
new Array:arrayMissionServerId
new Array:arrayMissionName
new Array:arrayMissionDesc
new Array:arrayMissionValueName
new Array:arrayMissionTargetValue
new Array:arrayMissionPrizeExp
new Array:arrayMissionPrizeMP

new gMenuMissionsPage[33]

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    mg_missions_arrayid_get(int:arrayMissionId, int:arrayMissionServerId, int:arrayMissionName, int:arrayMissionDesc, int:arrayMissionValueName, 
            _, _, int:arrayMissionTargetValue, int:arrayMissionPrizeExp, int:arrayMissionPrizeMP)
}

public plugin_natives()
{
    register_native("zi_menu_missions_open", "native_menu_missions_open")
}

menu_missions_open(id, mPage = 1)
{
    return true
}

public native_menu_missions_open(plugin_id, param_num)
{
    new id = get_param(1)

    if(!is_user_connected(id))
        return false
    
    return menu_missions_open(id)
}