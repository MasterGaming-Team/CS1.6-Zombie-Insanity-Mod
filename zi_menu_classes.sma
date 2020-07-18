#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <mg_core>
#include <zi_core>
#include <zi_menu_static>

#define PLUGIN "[MG][ZI] Class Menus"
#define VERSION "1.0"
#define AUTHOR "Vieni"

#define SUBZCLASS_IPP 5 // ITEM PER PAGE

new Array:arrayClassZombieId
new Array:arrayClassZombieDefSubClass
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

new gMenuSubClassState[33], gMenuSubClassCount[33], gMenuSubClassPicks[33][SUBZCLASS_IPP]
new gMenuZClassPage[33], gMenuSubClassPage[33]

new gMaxPlayers

public plugin_init()
{
    mg_core_command_reg("zclasses", "cmd_menu_open_zclasses")
    mg_core_command_reg("zclass", "cmd_menu_open_zclasses")
    mg_core_command_reg("hclasses", "cmd_menu_open_hclasses")
    mg_core_command_reg("hclass", "cmd_menu_open_hclasses")
    mg_core_command_reg("classes", "cmd_menu_open_classes")
    mg_core_command_reg("class", "cmd_menu_open_classes")

    gMaxPlayers = get_maxplayers()

    zi_core_arrayid_zombie_get(int:arrayClassZombieId, int:arrayClassZombieDefSubClass, int:arrayClassZombieName, int:arrayClassZombieDesc)
    zi_core_arrayid_zombiesub_get(int:arrayClassZombieSubParent, int:arrayClassZombieSubId, int:arrayClassZombieSubName, int:arrayClassZombieSubDesc,
                    _, _, int:arrayClassZombieSubHealth, int:arrayClassZombieSubSpeed, int:arrayClassZombieSubGravity)
    zi_core_arrayid_human_get(int:arrayClassHumanId, int:arrayClassHumanName, int:arrayClassHumanDesc)

    register_menu("MC ZombieClasses Menu", KEYSMENU, "menu_zclasses_handle")

    register_dictionary("zi_classmenus.txt")
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
        return false
    
    new menu[500], len, lZombieClassCount

    menu[0] = EOS
    len = 0
    lZombieClassCount = ArraySize(arrayClassZombieId)

    while(lZombieClassCount < mPage*7-7)
    {
		mPage -= 1
				
		if(mPage < 1)
		{
			zi_menu_open_main(id)
			return false
		}
	}

    new i, pickId, lClassName[64], lClassDesc[64], lPlayersNextClass

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

    gMenuZClassPage[id] = mPage

	// Fix for AMXX custom menus
    set_pdata_int(id, OFFSET_CSMENUCODE, 0)
    show_menu(id, KEYSMENU, menu, -1, "MC ZombieClasses Menu")
    return true
}

public menu_zclasses_handle(id, key)
{
    new lClassId = (gMenuZClassPage[id]-1)*7+key
    new lZombieClassCount = ArraySize(arrayClassZombieId)

    if(lClassId < lZombieClassCount && key < 7)
    {
    	menu_open_subzclasses(id, lClassId)
    	return PLUGIN_HANDLED
    }
    if(key == 7)
    {
    	if(gMenuZClassPage[id] != 1) gMenuZClassPage[id]--
    
    	menu_open_zclasses(id, gMenuZClassPage[id])
    	return PLUGIN_HANDLED
    }
    if(key == 8)
    {
    	if(gMenuZClassPage[id]*7 < lZombieClassCount) gMenuZClassPage[id]++

    	menu_open_zclasses(id, gMenuZClassPage[id])
    	return PLUGIN_HANDLED
    }
    if(key == 9)
		zi_menu_open_main(id)
	
    return PLUGIN_HANDLED
}

menu_open_subzclasses(id, classId, mPage = 1)
{
	if(!is_user_connected(id))
		return false

	new lClassName[64]
	new lCurrentClassHealth, lCurrentClassSpeed, lCurrentClassGravity

	ArrayGetString(arrayClassZombieName, zi_core_class_zombie_arrayslot_get(classId), lClassName, charsmax(lClassName))

	if(zi_core_client_zombie_get(id, true) == classId)
	{
		new lArrayId = zi_core_class_zombiesub_arrayslot_get(classId)

		lCurrentClassHealth = ArrayGetCell(arrayClassZombieSubHealth, lArrayId)
		lCurrentClassSpeed = ArrayGetCell(arrayClassZombieSubSpeed, lArrayId)
		lCurrentClassGravity = ArrayGetCell(arrayClassZombieSubGravity, lArrayId)
	}
	else
	{
		new lArrayId = zi_core_class_zombiesub_arrayslot_get(ArrayGetCell(arrayClassZombieDefSubClass, zi_core_class_zombie_arrayslot_get(classId)))

		lCurrentClassHealth = ArrayGetCell(arrayClassZombieSubHealth, lArrayId)
		lCurrentClassSpeed = ArrayGetCell(arrayClassZombieSubSpeed, lArrayId)
		lCurrentClassGravity = ArrayGetCell(arrayClassZombieSubGravity, lArrayId)
	}

	new menu[500], len, pickId = 1
	new lZombieSubClassCount = ArraySize(arrayClassZombieSubId), lClassCounter, lUserNextClass
	new bool:lClassAvailable, lCurrentClassName[64], lCurrentClassDesc[64], lCurrentSubClassCount
	new lCurrentClassId, lCurrentClassParent

	lUserNextClass = zi_core_client_zombiesub_get(id, true)

	len = mg_core_menu_title_create(id, "MC TITLE_SUBZCLASSES", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "  %L^n", id, "MC MENU_SUBZCLASSES1", id, lClassName)
	len += formatex(menu[len], charsmax(menu) - len, "  %L^n", id, "MC MENU_SUBZCLASSES2", mg_core_integer_to_formal(lCurrentClassHealth))
	len += formatex(menu[len], charsmax(menu) - len, "  %L^n", id, "MC MENU_SUBZCLASSES3", lCurrentClassSpeed, lCurrentClassGravity)
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	for(new lCurrentArrayId; lCurrentArrayId < lZombieSubClassCount && pickId < SUBZCLASS_IPP; lCurrentArrayId++)
	{
		lCurrentClassId = ArrayGetCell(arrayClassZombieSubId, lCurrentArrayId)
		lCurrentClassParent = ArrayGetCell(arrayClassZombieSubParent, lCurrentArrayId)

		if(lCurrentClassParent != classId)
			continue

		if(lClassCounter < mPage*SUBZCLASS_IPP-SUBZCLASS_IPP)
		{
			lCurrentSubClassCount++
			lClassCounter++
			continue
		}
		if(lClassCounter > mPage*SUBZCLASS_IPP-1)
		{
			lCurrentSubClassCount++
			continue
		}

		ArrayGetString(arrayClassZombieSubName, lCurrentArrayId, lCurrentClassName, charsmax(lCurrentClassName))
		ArrayGetString(arrayClassZombieSubDesc, lCurrentArrayId, lCurrentClassDesc, charsmax(lCurrentClassDesc))
		lClassAvailable = zi_core_client_zombiesub_available(id, lCurrentClassId)

		if(lClassAvailable)
		{
			if(lUserNextClass != lCurrentClassId)
			{
				len += formatex(menu[len], charsmax(menu) - len, "\r%d. \w%L  \r%L^n", pickId, id, lCurrentClassName, id, lCurrentClassDesc)
			}
			else
			{
				len += formatex(menu[len], charsmax(menu) - len, "\r%d. \y%L  \r%L^n", pickId, id, lCurrentClassName, id, lCurrentClassDesc)
			}
		}
		else
		{
			if(lUserNextClass != lCurrentClassId)
			{
				len += formatex(menu[len], charsmax(menu) - len, "\r%d. \w%L  \r%L^n", pickId, id, lCurrentClassName, id, lCurrentClassDesc)
			}
			else
			{
				len += formatex(menu[len], charsmax(menu) - len, "\r%d. \d%L  %L^n", pickId, id, lCurrentClassName, id, lCurrentClassDesc)
			}
		}

		gMenuSubClassPicks[id][pickId] = lCurrentArrayId
		lCurrentSubClassCount++
		pickId++
	}
	if(pickId == 1)
	{
		if(mPage == 1)
		{
			log_amx("[SUBZCLASSMENU] No subclasses were found for this class! (%d)", classId)
			menu_open_zclasses(id, gMenuZClassPage[id])
			return false
		}

		log_amx("[SUBZCLASSMENU] No subclasses were found on this page! (classId: %d | mPage:)", classId, mPage)
		return menu_open_subzclasses(id, classId, mPage - 1)
	}
	for(; pickId < SUBZCLASS_IPP; pickId++)
	{
		gMenuSubClassPicks[id][pickId] = -1
	}
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	if(lCurrentSubClassCount > SUBZCLASS_IPP)
	{
		if(mPage == 1)
			len += formatex(menu[len], charsmax(menu) - len, "\d8. %L^n", id, "MC MENU_BACK")
		else
			len += formatex(menu[len], charsmax(menu) - len, "\r8. \w%L^n", id, "MC MENU_BACK")
		
		if(mPage*SUBZCLASS_IPP >= lCurrentSubClassCount)
			len += formatex(menu[len], charsmax(menu) - len, "\d9. %L^n", id, "MC MENU_NEXT")
		else
			len += formatex(menu[len], charsmax(menu) - len, "\r9. \w%L^n", id, "MC MENU_NEXT")
	}
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w %L", id, "MC MENU_BACKTOZCLASSES")

	gMenuSubClassState[id] = classId
	gMenuSubClassPage[id] = mPage
	gMenuSubClassCount[id] = lCurrentSubClassCount

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "ZombieClasses SubMenu")
	
	return true
}

public menu_subzclasses_handle(id, key)
{
	if(key < SUBZCLASS_IPP)
	{
		if(gMenuSubClassPicks[id][key] != -1)
		{
			zi_core_client_zombie_set(id, _, gMenuSubClassPicks[id][key])
			menu_open_subzclasses(id, gMenuSubClassState[id], gMenuSubClassPage[id])
			return PLUGIN_HANDLED
		}
	}
	if(key == 7)
	{
    	if(gMenuSubClassPage[id] != 1) gMenuSubClassPage[id]--
    
    	menu_open_subzclasses(id, gMenuSubClassPage[id])
    	return PLUGIN_HANDLED
	}
	if(key == 8)
	{
    	if(gMenuSubClassPage[id]*SUBZCLASS_IPP < gMenuSubClassCount[id]) gMenuSubClassPage[id]++

    	menu_open_subzclasses(id, gMenuSubClassPage[id])
    	return PLUGIN_HANDLED
	}
	if(key == 9)
		menu_open_zclasses(id)

	return PLUGIN_HANDLED
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