#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <mg_core>
#include <zi_regsystem_menu>
#include <zi_core>
#include <zi_menu_classes>

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

	register_menu("MS Main Menu", KEYSMENU, "menu_main_handle")
	register_menu("MS Weapons Menu", KEYSMENU, "menu_weapons_handle")
	register_menu("MS Missions Menu", KEYSMENU, "menu_missions_handle")
	register_menu("MS Spectator Menu", KEYSMENU, "menu_spectator_handle")

	zi_core_arrayid_zombiesub_get(_, _, int:arrayClassZombieSubName)
	zi_core_arrayid_human_get(_, int:arrayClassHumanName)

	register_dictionary("zi_staticmenus.txt")
}

public plugin_natives()
{
	register_native("zi_menu_open_main", "native_menu_open_main")
	register_native("zi_menu_open_weapons", "native_menu_open_weapons")
}

public cmd_menu_open_main(id)
{
	menu_main_open(id)
	return PLUGIN_HANDLED
}

public clcmd_chooseteam(id)
{
	if(!(flag_get(gTeamMenuOverride, id)))
	{
		menu_main_open(id)
		return PLUGIN_HANDLED;
	}
	
	flag_set(gTeamMenuOverride, id)
	remove_task(id)
	return PLUGIN_CONTINUE;
}

public menu_main_open(id)
{
	static menu[500], len
	static lClassZombieSubName[64], lClassHumanName[40]
	
	menu[0] = EOS
	len = 0

	lClassZombieSubName[0] = EOS
	lClassHumanName[0] = EOS
	
	ArrayGetString(arrayClassZombieSubName, zi_core_class_zombiesub_arrayslot_get(zi_core_client_zombie_get(id, true)), lClassZombieSubName, charsmax(lClassZombieSubName))
	ArrayGetString(arrayClassHumanName, zi_core_class_human_arrayslot_get(zi_core_client_human_get(id, true)), lClassHumanName, charsmax(lClassHumanName))
	
	len = mg_core_menu_title_create(id, "MS TITLE_MAIN", menu, charsmax(menu), true)
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r1. \w%L^n", id, "MS MENU_MAIN1") // Elsődleges fegyvernév lekérése
	len += formatex(menu[len], charsmax(menu)-len, "\r2. \w%L^n", id, "MS MENU_MAIN2", id, lClassZombieSubName)
	len += formatex(menu[len], charsmax(menu)-len, "\r3. \w%L^n", id, "MS MENU_MAIN3", id, lClassHumanName)
	len += formatex(menu[len], charsmax(menu)-len, "\r4. \w%L^n", id, "MS MENU_MAIN4") // Ammo lekérése
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r5. \w%L^n", id, "MS MENU_MAIN5") // *Áruház*
	len += formatex(menu[len], charsmax(menu)-len, "\r6. \w%L^n", id, "MS MENU_MAIN6") // *VIP Menü*
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r7. \w%L^n", id, "MS MENU_MAIN7") // Beállítások
	len += formatex(menu[len], charsmax(menu)-len, "\r8. \w%L^n", id, "MS MENU_MAIN8") // Felhasználó/Reg menü
	len += formatex(menu[len], charsmax(menu)-len, "\r9. \w%L^n", id, "MS MENU_MAIN9") // Nyelvválasztás
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "^n0. \w%L", id, "MS MENU_EXIT")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MS Main Menu")
	
	return PLUGIN_HANDLED
}

public menu_main_handle(id, key)
{
	switch(key)
	{
		case 0:
		{
			menu_weapons_open(id)
		}
		case 1:
		{
			zi_menu_open_zclasses(id)
		}
		case 2:
		{
			zi_menu_open_hclasses(id)
		}
		case 3:
		{
			// Extra cucc menü megnyitása
		}
		case 4:
		{
			// Áruház megnyitása
		}
		case 5:
		{
			// VIP Menü megnyitása
		}
		case 6:
		{
			menu_settings_open(id)
		}
		case 7:
		{
			// Felhasználó/Regmenü megnyitása
		}
		case 8:
		{
			userSetNextLanguage(id)
			menu_main_open(id)
		}
	}

	return PLUGIN_HANDLED
}

public menu_weapons_open(id)
{
	static menu[500], len

	menu[0] = EOS
	len = 0

	len = mg_core_menu_title_create(id, "MS TITLE_WEAPONS", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r1. \w%L^n", id, "MS MENU_WEAPONS1") // Elsődleges fegyver lekérése
	len += formatex(menu[len], charsmax(menu)-len, "\r2. \w%L^n", id, "MS MENU_WEAPONS2") // Másodlagos fegyver lekérése
	len += formatex(menu[len], charsmax(menu)-len, "\r3. \w%L^n", id, "MS MENU_WEAPONS3") // Kés lekérése
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r4. \w%L^n", id, "MS MENU_WEAPONS4") // Támadó gránát lekérése
	len += formatex(menu[len], charsmax(menu)-len, "\r5. \w%L^n", id, "MS MENU_WEAPONS5") // Támogató gránát lekérése
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r0. \w%L", id, "MS MENU_EXIT")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MS Weapons Menu")
	
	return PLUGIN_HANDLED
}

public menu_weapons_handle(id, key)
{
	switch(key)
	{
		case 0:
		{
			// Elsődleges fegyvermenü megnyitása
		}
		case 1:
		{
			// Másodlagos fegyvermenü megnyitása
		}
		case 2:
		{
			// Kés menü megnyitása
		}
		case 3:
		{
			// Támadó gránát menü megnyitása
		}
		case 4:
		{
			// Támogató gránát menü megnyitása
		}
	}

	return PLUGIN_HANDLED
}

public menu_missions_open(id)
{
	// Lekérni, hogy bevan-e lépve. Ha nem, ne nyissa meg a menüt.

	static menu[500], len

	menu[0] = EOS
	len = 0

	len = mg_core_menu_title_create(id, "MS TITLE_MISSIONS", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r1. \w%L^n", id, "MS MENU_MISSIONS1") // Napi küldetések lekérése
	len += formatex(menu[len], charsmax(menu)-len, "\r2. \w%L^n", id, "MS MENU_MISSIONS2") // Heti küldetések lekérése
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r3. \w%L^n", id, "MS MENU_MISSIONS3") // Örök küldetések lekérése
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r0. \w%L", id, "MS MENU_EXIT")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MS Missions Menu")
	
	return PLUGIN_HANDLED
}

public menu_missions_handle(id, key)
{
	switch(key)
	{
		case 0:
		{
			// Megnyitni a napi küldetések menüt
		}
		case 1:
		{
			// Megnyitni a heti küldetések menüt
		}
		case 2:
		{
			// Megnyitni az örök küldetések menüt
		}
	}

	return PLUGIN_HANDLED
}

public menu_settings_open(id)
{
	static menu[500], len, CsTeams:lUserTeam

	menu[0] = EOS
	len = 0
	lUserTeam = cs_get_user_team(id)

	len = mg_core_menu_title_create(id, "MS TITLE_SETTINGS", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r1. \w%L^n", id, "MS MENU_SETTINGS1") // Effektek [FPS]
	len += formatex(menu[len], charsmax(menu)-len, "\r2. \w%L^n", id, "MS MENU_SETTINGS2") // Személyre Szabás
	len += formatex(menu[len], charsmax(menu)-len, "\r3. \w%L^n", id, "MS MENU_SETTINGS3") // Tiltások [némítás pl.]
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r4. \w%L^n", id, "MS MENU_SETTINGS4") // Prefix[Jelenlegi prefix lekérése]
	// Megnézni, hogy a játékos admin-e
	len += formatex(menu[len], charsmax(menu)-len, "\r5. \w%L^n", id, "MS MENU_SETTINGS5") // Admin menü

	if(lUserTeam == CS_TEAM_SPECTATOR)
		len += formatex(menu[len], charsmax(menu)-len, "\r6. \w%L^n", id, "MS MENU_SETTINGS6SPECTATOR") // Nezőbe állás
	else if(lUserTeam == CS_TEAM_T || lUserTeam == CS_TEAM_CT)
		len += formatex(menu[len], charsmax(menu)-len, "\r6. \w%L^n", id, "MS MENU_SETTINGS6PLAYING") // Játékba állás
	
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r0. \w%L", id, "MS MENU_EXIT")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MS Settings Menu")
	
	return PLUGIN_HANDLED
}

public menu_settings_handle(id, key)
{
	switch(key)
	{
		case 0:
		{
			// Megnyitni az effektek menüt
		}
		case 1:
		{
			// Megnyitni a személyre szabás menüt
		}
		case 2:
		{
			// Megnyitni a tiltások menüt
		}
		case 3:
		{
			// Megnyitni a prefix menüt
		}
		case 4:
		{
			// Megnyitni az admin menüt
		}
		case 5:
		{
			new CsTeams:lUserTeam = cs_get_user_team(id)

			if(lUserTeam == CS_TEAM_SPECTATOR)
			{
				flag_set(gTeamMenuOverride, id)
				set_task(1.0, "delete_menu_override", id)
			}
			else if(lUserTeam == CS_TEAM_CT || lUserTeam == CS_TEAM_T)
				menu_spectator_open(id)
		}
	}

	return PLUGIN_HANDLED
}

public delete_menu_override(id)
{
	flag_unset(gTeamMenuOverride, id)
}

public menu_spectator_open(id)
{
	new CsTeams:lUserTeam = cs_get_user_team(id)

	if(!(lUserTeam == CS_TEAM_CT || lUserTeam == CS_TEAM_T))
		return PLUGIN_HANDLED
	
	static menu[500], len

	menu[0] = EOS
	len = 0

	len = mg_core_menu_title_create(id, "MS TITLE_SPECTATOR", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r1. \w%L^n", id, "MS MENU_SPECTATOR1")
	len += formatex(menu[len], charsmax(menu)-len, "\r2. \w%L^n", id, "MS MENU_SPECTATOR2")
	len += formatex(menu[len], charsmax(menu)-len, "^n")
	len += formatex(menu[len], charsmax(menu)-len, "\r0. \w%L", id, "MS MENU_EXIT")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MS Spectator Menu")
	
	return PLUGIN_HANDLED
}

public menu_spectator_handle(id, key)
{
	switch(key)
	{
		case 0:
		{
			user_silentkill(id)
			cs_set_user_team(id, CS_TEAM_SPECTATOR)
		}
		case 1:
		{
			menu_settings_open(id)
		}
	}

	return PLUGIN_HANDLED
}

public native_menu_open_main(plugin_id, param_num)
{
	static id
	id = get_param(1)

	menu_main_open(id)

	return true
}

public native_menu_open_weapons(plugin_id, param_num)
{
	static id
	id = get_param(1)

	menu_weapons_open(id)

	return true
}

userSetNextLanguage(id)
{
	new lUserLang[3]
	get_user_info(id, "language", lUserLang, charsmax(lUserLang))

	new bool:lChanged = false

	for(new i; i < sizeof(mgLanguageList); i++)
	{
		if(equal(mgLanguageList[i], lUserLang))
		{
			if(i+1 >= sizeof(mgLanguageList))
			{
				copy(lUserLang, charsmax(lUserLang), mgLanguageList[0])
				lChanged = true
				break
			}
			else
			{
				copy(lUserLang, charsmax(lUserLang), mgLanguageList[i+1])
				lChanged = true
				break
			}
		}
	}

	if(!lChanged)
	{
		for(new i; i < sizeof(mgLanguageList); i++)
		{
			if(equal(mgLanguageList[i], mgDefLang))
			{
				if(i+1 >= sizeof(mgLanguageList))
				{
					copy(lUserLang, charsmax(lUserLang), mgLanguageList[0])
					lChanged = true
					break
				}
				else
				{
					copy(lUserLang, charsmax(lUserLang), mgLanguageList[i+1])
					lChanged = true
					break
				}
			}
		}
	}

	set_user_info(id, "lang", lUserLang)
}