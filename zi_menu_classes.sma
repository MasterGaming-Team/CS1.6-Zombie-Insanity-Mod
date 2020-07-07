#include <amxmodx>
#include <amxconst>
#include <fakemeta>
#include <mg_core>
#include <zi_core>

#define PLUGIN "[MG][ZI] Class Menus"
#define VERSION "1.0"
#define AUTHOR "Vieni"

new Array:arrayClassZombieId
new Array:arrayClassZombieName
new Array:arrayClassZombieDesc

new Array:arrayClassZombieSubParent
new Array:arrayClassZombieSubId
new Array:arrayClassZombieSubName
new Array:arrayClassZombieSubDesc
new Array:arrayClassZombieSubHealth
new Array:arrayClassZombieSubSpeed
new Array:arrayClassZombieSubGravity

new Array:arrayClassHumanId
new Array:arrayClassHumanName
new Array:arrayClassHumanDesc

new gPage[33]

new gMaxPlayers

public plugin_init()
{
    mg_core_command_reg("zclasses", "cmd_menu_open_zclasses")
    mg_core_command_reg("hclasses", "cmd_menu_open_hclasses")
    mg_core_command_reg("classes", "cmd_menu_open_classes")

    gMaxPlayers = get_maxplayers()

    zi_core_arrayid_zombie_get(int:arrayClassZombieId, int:arrayClassZombieName, int:arrayClassZombieDesc)
    zi_core_arrayid_zombiesub_get(int:arrayClassZombieSubParent, int:arrayClassZombieSubId, int:arrayClassZombieSubName, int:arrayClassZombieSubDesc,
                    _, _, int:arrayClassZombieSubHealth, int:arrayClassZombieSubSpeed, int:arrayClassZombieSubGravity)
    zi_core_arrayid_human_get(int:arrayClassHumanId, int:arrayClassHumanName, int:arrayClassHumanDesc)
}

public plugin_natives()
{
    register_native("zi_menu_open_zclasses", "native_menu_open_zclasses")
    register_native("zi_menu_open_hclasses", "native_menu_open_hclasses")
    register_native("zi_menu_open_classes", "native_menu_open_classes")
}

public cmd_menu_open_zclasses(id)
{
    menu_open_zclasses(id)
    return PLUGIN_HANDLED
}

public cmd_menu_open_hclasses(id)
{
    menu_open_hclasses(id)
    return PLUGIN_HANDLED
}

public cmd_menu_open_classes(id)
{
    if(zi_core_client_zombie_get(id))
        menu_open_zclasses(id)
    else
        menu_open_hclasses(id)
    
    return PLUGIN_HANDLED
}

menu_open_zclasses(id, mPage = 1)
{
    if(!is_user_connected(id))
        return
    
    static menu[500], len, lZombieClassCount

    menu[0] = EOS
    len = 0
    lZombieClassCount = ArraySize(arrayClassZombieSubId)

    while(lZombieClassCount < mPage*7-7)
    {
		mPage -= 1
				
		if(mPage < 1)
		{
			zp_menu_main_show(id)
			return false
		}
	}

    static i, pickId, lClassName[64], lClassDesc[64], lPlayersNextClass

    pickId = 1
    lPlayersNextClass = zi_core_client_zombie_get(id, true)

    len = mg_core_menu_title_create(id, "MC TITLE_ZCLASSES", menu, charsmax(menu))
    len += formatex(menu, charsmax(menu), "^n")

	for(i = mPage*7-7;(i < lZombieClassCount && i <= mPage*7-1); i++)
	{
		ArrayGetString(arrayClassZombieName, i, lClassName, charsmax(lClassName))
		ArrayGetString(arrayClassZombieDesc, i, lClassDesc, charsmax(lClassDesc))
		
		len += formatex(menu[len], charsmax(menu) - len, "\r%d. %s%L\r[\d%d\r] \d%L^n", pickId, lPlayersNextClass == i ? "\y":"\w",
                            id, lClassName, get_players_with_this_zclass(i), id, lClassDesc)
		
		pickId++
	}

    len += formatex(menu, charsmax(menu), "^n")
	len += formatex(menu[len], charsmax(menu) - len, "%s8.%s %L^n", mPage == 1 ? "\d":"\r", mPage == 1 ? "\d":"\w", id, "MC MENU_BACK")
	len += formatex(menu[len], charsmax(menu) - len, "%s9.%s %L^n", mPage*7 >= lZombieClassCount ? "\d":"\r", mPage*7 >= lZombieClassCount ? "\d":"\w", id, "MC MENU_NEXT")
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w %L", id, "MC MENU_BACKTOMAIN")

    gPage[id] = mPage

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MC ZombieClasses Menu")
}

public menu_open_hclasses(id, mPage = 1)
{
    if(!is_user_connected(id))
        return
    
    static menu[500], len
}

public native_menu_open_zclasses(plugin_id, param_num)
{
    new id = get_param(1)

    menu_open_zclasses(id)
    return true
}

public native_menu_open_hclasses(plugin_id, param_num)
{
    new id = get_param(1)

    menu_open_hclasses(id)
    return true
}

public native_menu_open_classes(plugin_id, param_num)
{
    new id = get_param(1)

    if(zi_core_client_zombie_get(id))
        menu_open_zclasses(id)
    else
        menu_open_hclasses(id)
    
    return true
}

get_players_with_this_zclass(classId)
{
    new lCount

    for(new i = 1; i <= gMaxPlayers, i++)
    {
        if(!is_user_connected(id))
            continue
        
        if(zi_core_client_zombie_get(i, true) == classId)
            lCount++
    }

    return lCount
}

get_players_with_this_hclass(classId)
{
    new lCount

    for(new i = 1; i <= gMaxPlayers, i++)
    {
        if(!is_user_connected(id))
            continue
        
        if(zi_core_client_human_get(i, true) == classId)
            lCount++
    }

    return lCount
}