#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <mg_core>
#include <zi_core>
#include <zi_menu_static>

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
    mg_core_command_reg("zclass", "cmd_menu_open_zclasses")
    mg_core_command_reg("hclasses", "cmd_menu_open_hclasses")
    mg_core_command_reg("hclass", "cmd_menu_open_hclasses")
    mg_core_command_reg("classes", "cmd_menu_open_classes")
    mg_core_command_reg("class", "cmd_menu_open_classes")

    gMaxPlayers = get_maxplayers()

    zi_core_arrayid_zombie_get(int:arrayClassZombieId, int:arrayClassZombieName, int:arrayClassZombieDesc)
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

    gPage[id] = mPage

	// Fix for AMXX custom menus
    set_pdata_int(id, OFFSET_CSMENUCODE, 0)
    show_menu(id, KEYSMENU, menu, -1, "MC ZombieClasses Menu")
    return true
}

public menu_zclasses_handle(id, key)
{
    new lClassId = (gPage[id]-1)*7+key
    new lZombieClassCount = ArraySize(arrayClassZombieId)

    if(lClassId < lZombieClassCount && key < 7)
    {
    	menu_open_subzclasses(id, lClassId)
    	return PLUGIN_HANDLED
    }
    if(key == 7)
    {
    	if(gPage[id] != 1) gPage[id]--
    
    	menu_open_zclasses(id, gPage[id])
    	return PLUGIN_HANDLED
    }
    if(key == 8)
    {
    	if(gPage[id]*7 < lZombieClassCount) gPage[id]++

    	menu_open_zclasses(id, gPage[id])
    	return PLUGIN_HANDLED
    }
    if(key == 9)
		zi_menu_open_main(id)
	
    return PLUGIN_HANDLED
}

public menu_open_subzclasses(id, classId)
{

}

show_submenu_zombieclasses(id, classId, mPage = 1)
{
	if(!is_user_connected(id) || is_user_bot(id))
		return false
		
	new menu[500]
	new len
	new pickId = 1
	
	new lClassZombieName[33], lClassZombieSubName[33], lClassZombieSubDesc[33]
	new lClassZombieSubHealth, Float:lClassZombieSubSpeed, Float:lClassZombieSubGravity
	new lClassZombieSubHealthStr[12]
	new lClassZombieSubCounter
	
	new lClassZombieSubCount = ArraySize(arrayClassZombieSubId)
	
	new tempClassId, bool:tempSubClassActivated
	
	ArrayGetString(arrayZombieClassName, classId, className, charsmax(className))

	for(new i; i < lZombieSubClassCount; i++)
	{
		if(classId == ArrayGetCell(gZombieSubClassGlobalId, i))
		{
			lClassZombieSubHealth = ArrayGetCell(arrayClassZombieSubHealth, i)
			lClassZombieSubHealthStr = mg_core_integer_to_formal(lClassZombieSubHealth)
			lClassZombieSubSpeed = Float:ArrayGetCell(arrayClassZombieSubSpeed, i)
			lClassZombieSubGravity = Float:ArrayGetCell(arrayClassZombieSubGravity, i)
			break
		}
	}
	
	len += formatex(menu[len], charsmax(menu) - len, "%s^n", createTitle(id, "TITLE_SUBZOMBIECLASSES"))
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "  %L^n", id, "MENU_SUBZOMBIECLASSES1", id, className)
	len += formatex(menu[len], charsmax(menu) - len, "  %L^n", id, "MENU_SUBZOMBIECLASSES2", classHealthStr)
	len += formatex(menu[len], charsmax(menu) - len, "  %L^n", id, "MENU_SUBZOMBIECLASSES3", classSpeed, classGravity)
	len += formatex(menu[len], charsmax(menu) - len, "  %L^n", id, "MENU_SUBZOMBIECLASSES4", classKnockback)
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	for(new i;i < lZombieSubClassCount; i++)
	{
		tempClassId = ArrayGetCell(gZombieSubClassGlobalId, i)
		
		if(tempClassId != classId)
			continue
		
		if(subClassCounter < mPage*4-4)
		{
			subClassCounter++
			continue
		}
		if(subClassCounter > mPage*4-1)
			break
		
		subClassCrit = ArrayGetCell(gZombieSubClassCrit, i)
		
		if(subClassCrit)
		{
			new retValue
			ExecuteForward(gForwardSubClassCritCheck, retValue, id, i)
			
			if(retValue == 0)
			{
				log_amx("[ZP] Didn't get sub zombie criterium from forward (%d)", i)
				continue
			}
			if(retValue == PLUGIN_HANDLED)	tempSubClassActivated = true
			else				tempSubClassActivated = false
		}
		else 	tempSubClassActivated = true
		
		ArrayGetString(gZombieSubClassName, i, subClassName, charsmax(subClassName))
		ArrayGetString(gZombieSubClassDesc, i, subClassDesc, charsmax(subClassDesc))
		
		if(!subClassCrit)
			len += formatex(menu[len], charsmax(menu) - len, "\r%d. %s%L  \r%L^n", pickId, gZombieSubClassNext[id] == i ? "\y":"\w", id, subClassName, id, subClassDesc)
		else
		{
			new subClassCritDesc[33]
			ArrayGetString(gZombieSubClassCritDesc, i, subClassCritDesc, charsmax(subClassCritDesc))
			
			if(tempSubClassActivated)
				len += formatex(menu[len], charsmax(menu) - len, "\r%d. %s%L \r%L  %L^n", pickId, gZombieSubClassNext[id] == i ? "\y":"\w", id, subClassName, id, subClassCritDesc, id, subClassDesc)
			else
				len += formatex(menu[len], charsmax(menu) - len, "\d%d. %L \r%L  %L^n", pickId, id, subClassName, id, subClassCritDesc, id, subClassDesc)
		}
		
		gSubClassesChosen[pickId-1][id] = i
		
		pickId++
	}
	for(new i=1; i<4; i++)	
		if(!gSubClassesChosen[i][id])
			gSubClassesChosen[i][id] = -1
	
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	//len += formatex(menu[len], charsmax(menu) - len, "  %s8.%s %L^n", mPage == 1 ? "\d":"\r", mPage == 1 ? "\d":"\w", id, "MENU_BACK")
	//len += formatex(menu[len], charsmax(menu) - len, "  %s9.%s %L^n", mPage*4 >= lZombieSubClassCount ? "\d":"\r", mPage*4 >= lZombieSubClassCount ? "\d":"\w", id, "MENU_NEXT")
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w %L", id, "MENU_EXIT")
	
	gPage[id] = mPage
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "ZombieClasses SubMenu")
	
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