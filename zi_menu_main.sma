#include <amxmodx>
#include <amxmisc>
#include <mg_core>

#define PLUGIN "[MG][ZI] Main Menu"
#define VERSION "1.0"
#define AUTHOR "Vieni"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_clcmd("chooseteam", "cmdChooseteam")

    mg_core_command_reg("menu", "cmdMenuMain")
    mg_core_command_reg("main", "cmdMenuMain")
    mg_core_command_reg("fomenu", "cmdMenuMain")
    mg_core_command_reg("mainmenu", "cmdMenuMain")

    mg_core_chatmessage_freq_reg("MMAIN_CHAT_OPENMENU")

	register_menu("MMainMain Menu", KEYSMENU, "menu_main")
	register_menu("MMainSpectator Menu", KEYSMENU, "menu_spectator")

    register_dictionary("zi_menumain.txt")
}

public plugin_natives()
{
    register_native("mg_zi_menu_main_open", "native_zi_menu_main_open")
}

public cmdMenuMain(id)
{

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
	static menu[500]
	static len, zmClassName[40], hmClassName[40], primaryName[40], classId[2]
	
	menu[0] = EOS
	len = 0
	primaryName[0] = EOS
	
	primaryName[0] = EOS
	zmClassName[0] = EOS
	hmClassName[0] = EOS
	
	zp_weapon_get_name(id, EBA_WEAPON_PRIMARY, primaryName, charsmax(primaryName)); strtoupper(primaryName)
			
	classId[0] = zp_class_zombie_next_get(id); classId[1] = zp_class_human_get_next(id)
	if(classId[0] == -1) classId[0] = 0
	if(classId[1] == -1) classId[1] = 0
	
	zp_class_zombie_get_name(classId[0], zmClassName, charsmax(zmClassName))
	zp_class_human_get_name(classId[1], hmClassName, charsmax(hmClassName))
			
	len += formatex(menu[len], charsmax(menu) - len, "%s^n", createTitle(id, "TITLE_MAIN", 1, ZP_VERSION_STR_LONG))
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L \r[\d%L\r]^n", id, "MENU_MAIN1", id, primaryName)
	len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L \r[\d%s Ammo\r]^n", id, "MENU_MAIN2", createFormalNumber(zp_bank_ammo_get(id)))
	len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L \r[\d%L\r]^n", id, "MENU_MAIN3", id, zmClassName)
	len += formatex(menu[len], charsmax(menu) - len, "\d4.\d %L \d[\d%s\d]^n", id, "MENU_MAIN4", hmClassName)
	len += formatex(menu[len], charsmax(menu) - len, "\y     ««¤===¤»»  ^n")
	len += formatex(menu[len], charsmax(menu) - len, "\d5.\d %L^n", id, "MENU_MAIN5")
	len += formatex(menu[len], charsmax(menu) - len, "\r6.\w %L^n", id, "MENU_MAIN6")
	len += formatex(menu[len], charsmax(menu) - len, "\y     ««¤===¤»»  ^n")
	if(cs_get_user_team(id) != CS_TEAM_SPECTATOR)
		len += formatex(menu[len], charsmax(menu) - len, "\r7.\w %L^n", id, "MENU_MAIN7")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r7.\w %L^n", id, "MENU_MAIN7SPECTATOR")
				
	len += formatex(menu[len], charsmax(menu) - len, "\r8.\w %L^n", id, "MENU_MAIN8")
	len += formatex(menu[len], charsmax(menu) - len, "\r9.\w %L^n", id, "MENU_MAIN9")
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w %L", id, "MENU_EXIT")
    
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "Main Menu")
	
	return PLUGIN_HANDLED
}

public native_zi_menu_main_open(plugin_id, param_num)
{
    static id
    id = get_param(1)

    show_menu_main(id)
    return true
}