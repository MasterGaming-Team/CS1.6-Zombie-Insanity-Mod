#include <amxmodx>
#include <amxmisc>
#include <mg_core>
#include <zi_core>

#define PLUGIN "[MG][ZI] Static Menus"
#define VERSION "1.0"
#define AUTHOR "Vieni"

#define flag_get(%1,%2) %1 & ((1 << (%2 & 31)))
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new Array:arrayClassZombieSubName
new Array:arrayClassHumanName

new gTeamMenuOverride

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	mg_core_command_reg("chooseteam", "cmd_menu_open_main")
	mg_core_command_reg("menu", "cmd_menu_open_main")
	mg_core_command_reg("main", "cmd_menu_open_main")
	mg_core_command_reg("fomenu", "cmd_menu_open_main")
	mg_core_command_reg("mainmenu", "cmd_menu_open_main")

    mg_core_chatmessage_freq_reg("MENU_MAIN_CHAT_OPENMENU")

	register_menu("SM Main Menu", KEYSMENU, "menu_main")
	register_menu("SM Spectator Menu", KEYSMENU, "menu_spectator")

	zi_core_arrayid_zombiesub_get(_, _, int:arrayClassZombieSubName)
	zi_core_arrayid_human_get(_, int:arrayClassHumanName)

    register_dictionary("zi_menumain.txt")
}

public plugin_natives()
{
	register_native("zi_menu_open_main", "native_menu_open_main")
}

public cmd_menu_open_main(id)
{
	show_menu_main(id)
}

public clcmd_chooseteam(id)
{
	if(flag_get(gTeamMenuOverride, id))
	{
		show_menu_main(id)
		return PLUGIN_HANDLED;
	}
	
	flag_set(gTeamMenuOverride, id)
	return PLUGIN_CONTINUE;
}

show_menu_main(id)
{
	static menu[500], len
	static lClassZombieSubName[64], lClassHumanName[40]
	
	menu[0] = EOS
	len = 0

	lClassZombieSubName[0] = EOS
	lClassHumanName[0] = EOS
	
	ArrayGetString(arrayClassZombieSubName, zi_core_class_zombiesub_arrayslot_get(zi_core_client_zombie_get(id, true)), lClassZombieSubName, charsmax(lClassZombieSubName))
	ArrayGetString(arrayClassHumanName, zi_core_class_human_arrayslot_get(zi_core_client_human_get(id, true), lClassHumanName, charsmax(lClassHumanName))
    
	len = mg_core_menu_title_create(id, "MS MENU_TITLE_MAIN", menu, charsmax(menu), true)
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r1. \wSZÖVEG1^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r2. \wSZÖVEG1^n")
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "^n0. \wKilépés")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "Main Menu")
	
	return PLUGIN_HANDLED
}

public native_menu_open_main(plugin_id, param_num)
{
    static id
    id = get_param(1)

    show_menu_main(id)

    return true
}