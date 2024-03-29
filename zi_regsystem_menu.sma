#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <mg_core>
#include <mg_regsystem_api>
#include <sqlx>
#include <zi_surface_missions>
#include <zi_menu_static>
#include <zi_regsystem_menu_const>

#define PLUGIN "[MG] Regsystem Menu"
#define VERSION "1.0"
#define AUTHOR "Vieni"

#define MENUITEM_IPP			7
#define MENUACTIVEITEMS_IPP		7

#define TASKID_MENUACTITEM		1

#define flag_get(%1,%2) %1 & ((1 << (%2 & 31)))
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new Array:arrayItemId
new Array:arrayItemName
new Array:arrayItemDesc
new Array:arrayItemCategory
new Array:arrayItemTime

new Array:arrayUserItemSortId[33]
new Array:arrayUserItemId[33]
new Array:arrayUserItemTime[33]
new Array:arrayUserItemUsed[33]
new Array:arrayUserItemCategory[33]

new bool:gItemsLoaded[33] = false

new Handle:gSqlItemTuple


new gUsername[33][MAX_USERNAME_LENGTH+1]
new gPassword[33][MAX_PASSWORD_LENGTH+1]
new gPasswordCheck[33][MAX_PASSWORD_LENGTH+1]
new gEMail[33][MAX_EMAIL_LENGTH+1]

new gMenuStoragePage[33]
new gMenuStoragePicks[33][MENUITEM_IPP]
new bool:gMenuStorageNextPage[33]

new gMenuItemArrayId[33]

new gMenuActiveItemsPage[33]
new gMenuActiveItemsPicks[33][MENUACTIVEITEMS_IPP]
new gMenuActiveItemsId
new bool:gMenuActiveItemsNextPage[33]

new gMenuActiveItemArrayId[33]


new gForwardItemGiven
new gForwardItemShow
new gForwardItemUse
new retValue

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	mg_core_command_reg("reg", "cmdReg")
	mg_core_command_reg("login", "cmdReg")
	mg_core_command_reg("register", "cmdReg")	

	register_clcmd("USERNAME_L", "msgLoginUsername")
	register_clcmd("PASSWORD_L", "msgLoginPassword")
	register_clcmd("USERNAME_R", "msgRegUsername")
	register_clcmd("PASSWORD1_R", "msgRegPassword")
	register_clcmd("PASSWORD2_R", "msgRegPasswordCheck")
	register_clcmd("EMAIL_R", "msgRegEMail")	

	register_menu("MR RegUserInfo Menu", KEYSMENU, "menu_userinfo_handle")
	register_menu("MR UserItems Menu", KEYSMENU, "menu_storage_handle")
	register_menu("MR ItemUse Menu", KEYSMENU, "menu_item_handle")
	register_menu("MR RegLoggedIn Menu", KEYSMENU, "menu_loggedin_handle")
	register_menu("MR RegLogin Menu", KEYSMENU, "menu_login_handle")
	register_menu("MR RegRegister Menu", KEYSMENU, "menu_register_handle")
	register_menu("MR ActiveItemList Menu", KEYSMENU, "menu_activeitemlist_handle")
	register_menu("MR ActiveItem Menu", KEYSMENU, "menu_activeitem_handle")

	gMenuActiveItemsId = register_menuid("MR ActiveItemList Menu")

	gForwardItemGiven = CreateMultiForward("mg_fw_client_item_added", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL) // id, user item id, user item array id
	gForwardItemShow = CreateMultiForward("mg_fw_client_item_show", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL) // id, user item id, user item array id
	gForwardItemUse = CreateMultiForward("mg_fw_client_item_use", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL) // id, user item id, user item array id

	register_dictionary("mg_regsystem.txt")

	loadValidItems()
	refreshUserItems()
}

public plugin_natives()
{
	gSqlItemTuple = SQL_MakeDbTuple("127.0.0.1", "MG_User", "fKj4zbI0wxwPoFzU", "cs_global")

	arrayItemId = ArrayCreate(1)
	arrayItemName = ArrayCreate(64)
	arrayItemDesc = ArrayCreate(64)
	arrayItemCategory = ArrayCreate(1)
	arrayItemTime = ArrayCreate(1)

	register_native("mg_reg_arrayid_item_get", "native_arrayid_item_get")
	register_native("mg_reg_arrayid_useritem_get", "native_arrayid_useritem_get")

	register_native("mg_item_client_give", "native_item_client_give")

	register_native("mg_menu_reg_open", "native_reg_open")
}

public cmdReg(id)
{
	if(!menu_loggedin_open(id))
		menu_userinfo_open(id)
	
	return PLUGIN_HANDLED
}

public menu_loggedin_open(id)
{
	if(!is_user_connected(id) || !mg_reg_user_loggedin(id))
		return false
		
	new menu[1024], len

	len = mg_core_menu_title_create(id, "MR_TITLE_LOGGEDIN", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 1.\w %L^n", id, "MR_MENU_LOGGEDIN1")   // Raktár
	len += formatex(menu[len], charsmax(menu) - len, "\r 2.\w %L^n", id, "MR_MENU_LOGGEDIN2")   // Aktivált itemek
	len += formatex(menu[len], charsmax(menu) - len, "\d 3. %L \r%L^n", id, "MR_MENU_LOGGEDIN3", id, "MR_MENU_UNDERCONSTRUCTION")   // Klán menü
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 4.\w %L^n", id, "MR_MENU_LOGGEDIN4")   // Küldetések[Napi/Heti/Örök]
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 5.\w %L: %L^n", id, "MR_MENU_LOGGEDIN5", id, mg_reg_user_setting_get(id) ? "MR_MENU_SETTINGON":"MR_MENU_SETTINGOFF")
	if(mg_reg_user_setting_get(id))
	{
		len += formatex(menu[len], charsmax(menu) - len, "    \d» \r6.\d %L\w: %L^n", id, "MR_MENU_LOGGEDIN6", id, mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINAUTHID) ? "MR_MENU_SETTINGON":"MR_MENU_SETTINGOFF")
		len += formatex(menu[len], charsmax(menu) - len, "    \d» \r7.\d %L\w: %L^n", id, "MR_MENU_LOGGEDIN7", id, mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINNAME) ? "MR_MENU_SETTINGON":"MR_MENU_SETTINGOFF")
		len += formatex(menu[len], charsmax(menu) - len, "    \d» \r8.\d %L\w: %L^n", id, "MR_MENU_LOGGEDIN8", id, mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINSETINFO) ? "MR_MENU_SETTINGON":"MR_MENU_SETTINGOFF")
	}
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 9.\w %L^n", id, "MR_MENU_LOGGEDIN9")   // Kijelentkezés
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r						0.\w %L", id, "MR_MENU_BACKTOMAIN")
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR RegLoggedIn Menu")
	
	return true
}

public menu_loggedin_handle(id, key)
{
	switch(key)
	{
		case 0:
		{
			menu_storage_open(id)
		}
		case 1:
		{
			menu_activeitemlist_open(id)
		}
		case 2:
		{
			// Klán geci
			menu_loggedin_open(id)
		}
		case 3:
		{
			zi_menu_missions_open(id)
		}
		case 4:
		{
			if(mg_reg_user_setting_get(id))
			{
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGIN, false)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINAUTHID, false)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINNAME, false)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINSETINFO, false)
			}
			else
			{
				checkUserSetinfoPW(id)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGIN, true)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINAUTHID, true)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINNAME, true)
				mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINSETINFO, true)
			}
			menu_loggedin_open(id)
		}
		case 5:
		{
			if(mg_reg_user_setting_get(id))
			{
				if(mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINAUTHID))
				{
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINAUTHID, false)

					if(!mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINNAME) && !mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINSETINFO))
						mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGIN, false)
				}
				else
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINAUTHID, true)
			}
			menu_loggedin_open(id)
		}
		case 6:
		{
			if(mg_reg_user_setting_get(id))
			{
				if(mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINNAME))
				{
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINNAME, false)

					if(!mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINAUTHID) && !mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINSETINFO))
						mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGIN, false)
				}
				else
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINNAME, true)
			}
			menu_loggedin_open(id)
		}
		case 7:
		{
			if(mg_reg_user_setting_get(id))
			{
				if(mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINSETINFO))
				{
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINSETINFO, false)
				
					if(!mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINAUTHID) && !mg_reg_user_setting_get(id, MG_SETTING_AUTOLOGINNAME))
						mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGIN, false)
				}
				else
				{
					checkUserSetinfoPW(id)
					mg_reg_user_setting_set(id, MG_SETTING_AUTOLOGINSETINFO, true)
				}
			}
			menu_loggedin_open(id)
		}
		case 8:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGOUTPROCESS")
			mg_reg_user_logout(id)
		}
		case 9:
		{
			zi_menu_open_main(id)
		}
	}
	
	return PLUGIN_HANDLED
}

menu_storage_open(id, mPage = 1)
{
	if(!is_user_connected(id))
        return false
    
	new menu[500]
	new len
	new lUserItemArrayIdList[MENUITEM_IPP] = -1

	gMenuStorageNextPage[id] = getVisibleItems(id, arrayUserItemId[id], lUserItemArrayIdList, sizeof(lUserItemArrayIdList), mPage)

	while(lUserItemArrayIdList[0] == -1)
	{
		mPage -= 1
				
		if(mPage <= 1)
		{
			mPage = 1
			break
		}

		gMenuStorageNextPage[id] = getVisibleItems(id, arrayUserItemId[id], lUserItemArrayIdList, sizeof(lUserItemArrayIdList), mPage)
	}

	new pickId = 1
	new lItemName[64]
	new lUserItemId
	new lItemArrayId

	len = mg_core_menu_title_create(id, "MR_TITLE_STORAGE", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")

	for(new i; i < sizeof(lUserItemArrayIdList); i++)
	{
		if(lUserItemArrayIdList[i] == -1)
			break

		lUserItemId = ArrayGetCell(arrayUserItemId[id], lUserItemArrayIdList[i])
		lItemArrayId = ArrayFindValue(arrayItemId, lUserItemId)

		ExecuteForward(gForwardItemShow, retValue, id, lUserItemId, lUserItemArrayIdList[i])

		ArrayGetString(arrayItemName, lItemArrayId, lItemName, charsmax(lItemName))
		
		if(retValue == ITEM_HANDLED)
			len += formatex(menu[len], charsmax(menu) - len, "\r %d. %L^n", pickId, id, lItemName)
		else
			len += formatex(menu[len], charsmax(menu) - len, "\d %d. %L^n", pickId, id, lItemName)

		pickId++
	}

	gMenuStoragePicks[id] = lUserItemArrayIdList

	if(pickId == 1)
	{
		len += formatex(menu[len], charsmax(menu) - len, "\y %L^n", id, "MR_MENU_NOAVAILABLEITEM")
	}

	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	if(mPage <= 1)
		len += formatex(menu[len], charsmax(menu) - len, "\d						8. %L^n", id, "MR_MENU_BACK")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r						8. \w%L^n", id, "MR_MENU_BACK")
	
	if(!gMenuStorageNextPage[id])
		len += formatex(menu[len], charsmax(menu) - len, "\d						9. %L^n", id, "MR_MENU_NEXT")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r						9. \w%L^n", id, "MR_MENU_NEXT")
	
	len += formatex(menu[len], charsmax(menu) - len, "\r						0.\w %L", id, "MR_MENU_BACKSTEP")

	gMenuStoragePage[id] = mPage

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR UserItems Menu")
	return true
}

public menu_storage_handle(id, key)
{
	if(key >= 0 && key < MENUITEM_IPP)
	{
		new lUserItemArrayId = -1

		lUserItemArrayId = gMenuStoragePicks[id][key]

		if(lUserItemArrayId == -1)
		{
			return PLUGIN_HANDLED
		}

		if(!checkUserItemAccessibility(id, lUserItemArrayId))
		{
			menu_storage_open(id, gMenuStoragePage[id])
			return PLUGIN_HANDLED
		}

		menu_item_open(id, lUserItemArrayId)
		return PLUGIN_HANDLED
	}

	switch(key)
	{
		case 7:
		{
			if(gMenuStoragePage[id] > 1)
			{
				gMenuStoragePage[id]--
				menu_storage_open(id, gMenuStoragePage[id])
			}
		}
		case 8:
		{
			if(gMenuStorageNextPage[id])
			{
				gMenuStoragePage[id]++
				menu_storage_open(id, gMenuStoragePage[id])
			}
		}
		case 9:
		{
			menu_loggedin_open(id)
		}
	}
	
	return PLUGIN_HANDLED
}

public menu_item_open(id, userItemArrayId)
{
	new lItemArrayId = ArrayFindValue(arrayItemId, ArrayGetCell(arrayUserItemId[id], userItemArrayId))

	if(lItemArrayId == -1)
	{
		menu_storage_open(id, gMenuStoragePage[id])
		return false
	}

	new lItemName[64]
	new lItemDesc[64]
	new lItemUnixTime = ArrayGetCell(arrayItemTime, lItemArrayId)

	new lItemTimeDay
	new lItemTimeHour
	new lItemTimeMinute
	new lItemTimeSecond

	ArrayGetString(arrayItemName, lItemArrayId, lItemName, charsmax(lItemName))
	ArrayGetString(arrayItemDesc, lItemArrayId, lItemDesc, charsmax(lItemDesc))

	unixToItemTime(lItemUnixTime, lItemTimeDay, lItemTimeHour, lItemTimeMinute, lItemTimeSecond)

	new lStrTime[60]
	new len

	if(lItemTimeDay)
		len += formatex(lStrTime[len], charsmax(lStrTime) - len, "%d %L ", lItemTimeDay, id, "MR_ITEMTIME_DAY")

	if(lItemTimeHour)
		len += formatex(lStrTime[len], charsmax(lStrTime) - len, "%d %L ", lItemTimeHour, id, "MR_ITEMTIME_HOUR")

	if(lItemTimeMinute)
		len += formatex(lStrTime[len], charsmax(lStrTime) - len, "%d %L ", lItemTimeMinute, id, "MR_ITEMTIME_MINUTE")

	if(lItemTimeSecond)
		len += formatex(lStrTime[len], charsmax(lStrTime) - len, "%d %L ", lItemTimeSecond, id, "MR_ITEMTIME_SECOND")
	
	new menu[500]
	len = 0

	len = mg_core_menu_title_create(id, "MR_TITLE_ITEM", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, " [#%d]^n", userItemArrayId+1)
	len += formatex(menu[len], charsmax(menu) - len, "  %L: %L^n", id, "MR_MENU_ITEM_NAME", id, lItemName)
	len += formatex(menu[len], charsmax(menu) - len, "  %L: %s^n", id, "MR_MENU_ITEM_TIME", lStrTime)
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "%L^n", id, lItemDesc)
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 1. %L^n", id, "MR_MENU_ITEM1")
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\d						8. %L^n", id, "MR_MENU_BACK")
	len += formatex(menu[len], charsmax(menu) - len, "\d						9. %L^n", id, "MR_MENU_NEXT")
	len += formatex(menu[len], charsmax(menu) - len, "\d						0. %L^n", id, "MR_MENU_BACKSTEP")

	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR ItemUse Menu")
	return true
}

public menu_item_handle(id, key)
{
	new lUserItemArrayId = gMenuItemArrayId[id]

	switch(key)
	{
		case 0:
		{
			if(lUserItemArrayId == -1)
			{
				menu_storage_open(id, gMenuStoragePage[id])
				return PLUGIN_HANDLED
			}

			if(!checkUserItemAccessibility(id, lUserItemArrayId))
			{
				menu_storage_open(id, gMenuStoragePage[id])
				return PLUGIN_HANDLED
			}

			if(checkUserItemCategoryUsed(id, ArrayGetCell(arrayUserItemCategory[id], lUserItemArrayId)))
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "MR_CHAT_ITEMCATEGORYUSED")
				menu_item_open(id, lUserItemArrayId)
				return PLUGIN_HANDLED
			}

			ExecuteForward(gForwardItemUse, retValue, id, ArrayGetCell(arrayUserItemId[id], lUserItemArrayId), lUserItemArrayId)

			if(retValue == ITEM_CONTINUE)
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "MR_CHAT_ITEMCANTBEUSED")
				menu_item_open(id, lUserItemArrayId)
				return PLUGIN_HANDLED
			}

			ArraySetCell(arrayUserItemUsed[id], lUserItemArrayId, 1)
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "MR_CHAT_ITEMUSED")
			menu_storage_open(id, gMenuStoragePage[id])
		}
		case 7:
		{
			new lArraySize = ArraySize(arrayUserItemUsed[id])
			new itemCount
			new i = lUserItemArrayId

			while(!checkUserItemAccessibility(id, i))
			{
				if(itemCount >= lArraySize)
				{
					menu_storage_open(id, gMenuStoragePage[id])
					return PLUGIN_HANDLED
				}

				if(i <= 0)
				{
					i = lArraySize - 1
					continue
				}
				
				itemCount++
				i--
			}

			menu_item_open(id, i)
		}
		case 8:
		{
			new lArraySize = ArraySize(arrayUserItemUsed[id])
			new itemCount
			new i = lUserItemArrayId

			while(!checkUserItemAccessibility(id, i))
			{
				if(itemCount >= lArraySize)
				{
					menu_storage_open(id, gMenuStoragePage[id])
					return PLUGIN_HANDELD
				}

				if(i+1 >= lArraySize)
				{
					i = 0
					continue
				}
				
				itemCount++
				i++
			}

			menu_item_open(id, i)
		}
		case 9:
		{
			menu_storage_open(id, gMenuStoragePage[id])
		}
	}

	return PLUGIN_HANDLED
}

menu_activeitemlist_open(id, mPage = 1)
{
	if(!is_user_connected(id))
        return false
    
	new menu[500]
	new len
	new lUserItemArrayIdList[MENUACTIVEITEMS_IPP] = -1
	
	gMenuActiveItemsNextPage[id] = getActiveItems(id, arrayUserItemId[id], lUserItemArrayIdList, sizeof(lUserItemArrayIdList), mPage)

	while(lUserItemArrayIdList[0] == -1)
	{
		mPage -= 1
				
		if(mPage <= 1)
		{
			mPage = 1
			break
		}

		gMenuActiveItemsNextPage[id] = getActiveItems(id, arrayUserItemId[id], lUserItemArrayIdList, sizeof(lUserItemArrayIdList), mPage)
	}

	new pickId = 1
	new lItemName[64]
	new lUserItemId
	new lItemArrayId

	new lStrTime[90]
	new lTimeLen
	new lItemTimeDay
	new lItemTimeHour
	new lItemTimeMinute
	new lItemTimeSecond

	len = mg_core_menu_title_create(id, "MR_TITLE_ACTIVEITEMS", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")

	for(new i; i < sizeof(lUserItemArrayIdList); i++)
	{
		if(lUserItemArrayIdList[i] == -1)
			break

		lUserItemId = ArrayGetCell(arrayUserItemId[id], lUserItemArrayIdList[i])
		lItemArrayId = ArrayFindValue(arrayItemId, lUserItemId)

		ArrayGetString(arrayItemName, lItemArrayId, lItemName, charsmax(lItemName))
		
		unixToItemTime(ArrayGetCell(arrayUserItemTime[id], lUserItemArrayIdList[i]) - get_systime(), lItemTimeDay, lItemTimeHour, lItemTimeMinute, lItemTimeSecond)

		if(lItemTimeDay)
			lTimeLen += formatex(lStrTime[len], charsmax(lStrTime) - len, "[%d%L ", lItemTimeDay, id, "MR_ITEMTIME_DAY")
		
		lTimeLen += formatex(lStrTime[len], charsmax(lStrTime) - len, "%s%d:%s%d:%s%d]",
					lItemTimeHour < 10 ? "0":"", lItemTimeHour, lItemTimeMinute < 10 ? "0":"", lItemTimeMinute, lItemTimeSecond < 10 ? "0":"", lItemTimeSecond)

		if(retValue == ITEM_HANDLED)
			len += formatex(menu[len], charsmax(menu) - len, "\r %d. %L %s^n", pickId, id, lItemName, lStrTime)
		else
			len += formatex(menu[len], charsmax(menu) - len, "\d %d. %L %s^n", pickId, id, lItemName, lStrTime)

		lStrTime[0] = EOS
		lTimeLen = 0

		pickId++
	}

	gMenuStoragePicks[id] = lUserItemArrayIdList

	if(pickId == 1)
	{
		len += formatex(menu[len], charsmax(menu) - len, "\y %L^n", id, "MR_MENU_NOAVAILABLEITEM")
	}
	
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")

	if(mPage <= 1)
		len += formatex(menu[len], charsmax(menu) - len, "\d						8. %L^n", id, "MR_MENU_BACK")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r						8. \w%L^n", id, "MR_MENU_BACK")
		
	if(!gMenuActiveItemsNextPage[id])
		len += formatex(menu[len], charsmax(menu) - len, "\d						9. %L^n", id, "MR_MENU_NEXT")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r						9. \w%L^n", id, "MR_MENU_NEXT")
	
	len += formatex(menu[len], charsmax(menu) - len, "\r						0.\w %L", id, "MR_MENU_BACKSTEP")

	gMenuStoragePage[id] = mPage

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR ActiveItemList Menu")

	remove_task(TASKID_MENUACTITEM+id)
	set_task(1.0, "menu_activeitemlist_refresh", TASKID_MENUACTITEM+id)

	return true
}

public menu_activeitemlist_refresh(taskid)
{
	new id = taskid - TASKID_MENUACTITEM
	new lMenuId
	new lMenuKeys
	
	get_user_menu(id, lMenuId, lMenuKeys)
	
	if(lMenuId != gMenuActiveItemsId)
		return
	
	menu_activeitemlist_open(id, gMenuActiveItemsPage[id])
}

public menu_activeitemlist_handle(id, key)
{
	// While there's time between the handle and the menu, this is neccessary 'cause of the menu refreshing[W/o this the menu could stay opened]
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)

	if(key >= 0 && key < MENUACTIVEITEMS_IPP)
	{
		new lUserItemArrayId = -1

		lUserItemArrayId = gMenuActiveItemsPicks[id][key]

		if(lUserItemArrayId == -1)
		{
			return PLUGIN_HANDLED
		}

		if(!checkUserItemAccessibility(id, lUserItemArrayId))
		{
			menu_activeitemlist_open(id, gMenuActiveItemsPage[id])
			return PLUGIN_HANDLED
		}

		menu_activeitem_open(id, lUserItemArrayId)
		return PLUGIN_HANDLED
	}

	switch(key)
	{
		case 7:
		{
			if(gMenuActiveItemsPage[id] > 1)
			{
				gMenuActiveItemsPage[id]--
				menu_activeitemlist_open(id, gMenuActiveItemsPage[id])
			}
		}
		case 8:
		{
			if(gMenuActiveItemsNextPage[id])
			{
				gMenuActiveItemsPage[id]++
				menu_activeitemlist_open(id, gMenuActiveItemsPage[id])
			}
		}
		case 9:
		{
			menu_loggedin_open(id)
		}
	}
	
	return PLUGIN_HANDLED
}

public menu_activeitem_open(id, userItemArrayId)
{
	new lItemArrayId = ArrayFindValue(arrayItemId, ArrayGetCell(arrayUserItemId[id], userItemArrayId))

	if(lItemArrayId == -1)
	{
		menu_storage_open(id, gMenuStoragePage[id])
		return false
	}

	new lItemName[64]
	new lItemDesc[64]
	new lItemUnixTime = ArrayGetCell(arrayItemTime, lItemArrayId)

	ArrayGetString(arrayItemName, lItemArrayId, lItemName, charsmax(lItemName))
	ArrayGetString(arrayItemDesc, lItemArrayId, lItemDesc, charsmax(lItemDesc))

	new lStrTime[60]

	format_time(lStrTime, charsmax(lStrTime), "%Y/%m/%d - %H:%M%S", lItemUnixTime)
	
	new menu[500]
	new len

	len = mg_core_menu_title_create(id, "MR_TITLE_ITEM", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, " [#%d]^n", userItemArrayId+1)
	len += formatex(menu[len], charsmax(menu) - len, "  %L: %L^n", id, "MR_MENU_ITEM_NAME", id, lItemName)
	len += formatex(menu[len], charsmax(menu) - len, "  %L: %s^n", id, "MR_MENU_ITEM_TIME", lStrTime)
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, " %L^n", id, lItemDesc)
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\d						8. %L^n", id, "MR_MENU_BACK")
	len += formatex(menu[len], charsmax(menu) - len, "\d						9. %L^n", id, "MR_MENU_NEXT")
	len += formatex(menu[len], charsmax(menu) - len, "\d						0. %L^n", id, "MR_MENU_BACKSTEP")

	gMenuActiveItemArrayId[id] = userItemArrayId

	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR ActiveItem Menu")
	return true
}

public menu_activeitem_handle(id, key)
{
	new lUserItemArrayId = gMenuActiveItemArrayId[id]

	switch(key)
	{
		case 7:
		{
			new lArraySize = ArraySize(arrayUserItemUsed[id])
			new itemCount
			new i = lUserItemArrayId

			while(checkUserItemAccessibility(id, i))
			{
				if(itemCount >= lArraySize)
				{
					menu_activeitemlist_open(id, gMenuActiveItemsPage[id])
					return PLUGIN_HANDLED
				}

				if(i <= 0)
				{
					i = lArraySize - 1
					continue
				}

				itemCount++
				i--
			}

			menu_activeitem_open(id, i)
		}
		case 8:
		{
			new lArraySize = ArraySize(arrayUserItemUsed[id])
			new itemCount
			new i = lUserItemArrayId

			while(checkUserItemAccessibility(id, i))
			{
				if(itemCount >= lArraySize)
				{
					menu_activeitemlist_open(id, gMenuActiveItemsPage[id])
					return PLUGIN_HANDLED
				}

				if(i+1 >= lArraySize)
				{
					i = 0
					continue
				}
				
				itemCount++
				i++
			}

			menu_activeitem_open(id, i)
		}
		case 9:
		{
			menu_activeitemlist_open(id, gMenuActiveItemsPage[id])
		}
	}

	return PLUGIN_HANDLED
}

public menu_userinfo_open(id)
{
	if(!is_user_connected(id) || mg_reg_user_loggedin(id))
		return false
		
	new menu[500], len

	len = mg_core_menu_title_create(id, "MR_TITLE_USERINFO", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "  %L^n", id, "MR_MENU_USERINFO0")
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 1.\w %L^n", id, "MR_MENU_USERINFO1")
	len += formatex(menu[len], charsmax(menu) - len, "\r 2.\w %L^n", id, "MR_MENU_USERINFO2")
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 4.\w %L^n", id, "MR_MENU_USERINFO4")
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r						0.\w %L", id, "MR_MENU_BACKTOMAIN")

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR RegUserInfo Menu")
	
	return true
}

public menu_userinfo_handle(id, key)
{
	switch(key)
	{
		case 0: 
		{
			menu_login_open(id)
		}
		case 1:
		{
			menu_register_open(id)
		}
		case 3:
		{
			userSetNextLanguage(id)
			menu_userinfo_open(id)
		}
		case 9:
		{
			zi_menu_open_main(id)
		}
	}
	
	return PLUGIN_HANDLED
}

public menu_login_open(id)
{
	if(!is_user_connected(id) || mg_reg_user_loggedin(id))
		return false
		
	new menu[500], len

	len = mg_core_menu_title_create(id, "MR_TITLE_LOGIN", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	
	if(gUsername[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r 1.\w %L \r%s^n", id, "MR_MENU_LOGIN1", gUsername[id])
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r 1.\w %L \r%L^n", id, "MR_MENU_LOGIN1", id, "MR_MENU_NOUSERNAME")
	
	if(gPassword[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r 2.\w %L \r*****^n", id, "MR_MENU_LOGIN2")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r 2.\w %L \r%L^n", id, "MR_MENU_LOGIN2", id, "MR_MENU_NOPASSWORD")
	
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 3.\w %L^n", id, "MR_MENU_LOGIN3")
	len += formatex(menu[len], charsmax(menu) - len, "\r 4.\w %L^n", id, "MR_MENU_LOGIN4")
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r						0.\w %L", id, "MR_MENU_STEPBACK")
			
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR RegLogin Menu")
	
	return true
}

public menu_login_handle(id, key)
{
	if(mg_reg_user_loggedin(id))
		return PLUGIN_HANDLED

	switch(key)
	{
		case 0:
		{
			client_cmd(id, "messagemode USERNAME_L")
		}
		case 1:
		{
			client_cmd(id, "messagemode PASSWORD_L")
		}
		case 2:
		{
			if(mg_reg_user_loading(id))
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
				menu_login_open(id)
				return PLUGIN_HANDLED
			}
			
			if(!gUsername[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOUSERNAMEGIVEN")
				menu_login_open(id)
				return PLUGIN_HANDLED
			}
			
			if(!gPassword[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOPASSWORDGIVEN")
				menu_login_open(id)
				return PLUGIN_HANDLED
			}
			
			new lHashPassword[33]
			hash_string(gPassword[id], Hash_Md5, lHashPassword, charsmax(lHashPassword))

			mg_reg_user_login(id, gUsername[id], lHashPassword)
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINPLSWAIT")
		}
		case 3:
		{
			userSetNextLanguage(id)
			menu_login_open(id)
		}
		case 9:
		{
			menu_userinfo_open(id)
		}
	}
	
	return PLUGIN_HANDLED
}

public menu_register_open(id)
{
	if(!is_user_connected(id) || mg_reg_user_loggedin(id))
		return false
		
	new menu[500], len
		
	len = mg_core_menu_title_create(id, "MR_TITLE_REGISTER", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	
	if(gUsername[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r 1.\w %L \r%s^n", id, "MR_MENU_REGISTER1", gUsername[id])
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r 1.\w %L \r%L^n", id, "MR_MENU_REGISTER1", id, "MR_MENU_NOUSERNAME")
	
	if(gPassword[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r 2.\w %L \r*****^n", id, "MR_MENU_REGISTER2")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r 2.\w %L \r%L^n", id, "MR_MENU_REGISTER2", id, "MR_MENU_NOPASSWORD")
	
	
	if(gPasswordCheck[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r 3.\w %L \r*****^n", id, "MR_MENU_REGISTER3")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r 3.\w %L \r%L^n", id, "MR_MENU_REGISTER3", id, "MR_MENU_NOPASSWORD")

	if(gEMail[id][0])
		len += formatex(menu[len], charsmax(menu) - len, "\r 4.\w %L \r%s^n", id, "MR_MENU_REGISTER4", gEMail[id])
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r 4.\w %L \r%s^n", id, "MR_MENU_REGISTER4", "......@****.***")
	
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 5.\w %L^n", id, "MR_MENU_REGISTER5")
	len += formatex(menu[len], charsmax(menu) - len, "\r 6.\w %L^n", id, "MR_MENU_REGISTER6")
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r						0.\w %L", id, "MR_MENU_STEPBACK")
			
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR RegRegister Menu")
	
	return true
}

public menu_register_handle(id, key)
{
	if(mg_reg_user_loggedin(id))
		return PLUGIN_HANDLED
	
	switch(key)
	{
		case 0:
		{
			client_cmd(id, "messagemode USERNAME_R")
		}
		case 1:
		{
			client_cmd(id, "messagemode PASSWORD1_R")
		}
		case 2:
		{
			client_cmd(id, "messagemode PASSWORD2_R")
		}
		case 3:
		{
			client_cmd(id, "messagemode EMAIL_R")
		}
		case 4:
		{
			if(mg_reg_user_loading(id))
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
				menu_login_open(id)
				return PLUGIN_HANDLED
			}
			
			if(!gUsername[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOUSERNAMEGIVEN")
				menu_register_open(id)
				return PLUGIN_HANDLED
			}
			
			if(!gPassword[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOPASSWORDGIVEN")
				menu_register_open(id)
				return PLUGIN_HANDLED
			}
			
			if(!gPasswordCheck[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_NOPASSWORD2GIVEN")
				menu_register_open(id)
				return PLUGIN_HANDLED
			}

			if(!gEMail[id][0])
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_EMAILGIVEN")
				menu_register_open(id)
				return PLUGIN_HANDLED
			}
			
			if(!equal(gPassword[id], gPasswordCheck[id]))
			{
				mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_PASSWORDSNOTSAME")
				menu_register_open(id)
				return PLUGIN_HANDLED
			}
			
			new lHashPassword[33]
			hash_string(gPassword[id], Hash_Md5, lHashPassword, charsmax(lHashPassword))

			mg_reg_user_register(id, gUsername[id], lHashPassword, gEMail[id])
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_REGPLSWAIT")
		}
		case 5:
		{
			userSetNextLanguage(id)
			menu_register_open(id)
		}
		case 9:
		{
			menu_userinfo_open(id)
		}
	}
	
	return PLUGIN_HANDLED
}

public sql_item_load_handle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        log_amx("%s", error)
        return
	}

	new lItemId
	new lItemName[64]
	new lItemDesc[64]

	while(SQL_MoreResults(Query))
	{
		lItemId = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemId"))

		if(ArrayFindValue(arrayItemId, lItemId) != -1)
		{
			log_amx("[ITEMLOADING] An item id has been registered more than once!! (%d)", lItemId)
			SQL_NextRow(Query)
			continue
		}

		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemName"), lItemName, charsmax(lItemName))
		SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemDesc"), lItemDesc, charsmax(lItemDesc))

		ArrayPushCell(arrayItemId, lItemId)
		ArrayPushString(arrayItemName, lItemName)
		ArrayPushString(arrayItemDesc, lItemDesc)
		ArrayPushCell(arrayItemCategory, SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemCategory")))
		ArrayPushCell(arrayItemTime, SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemTime")))
		SQL_NextRow(Query)
	}
}

public sql_item_refresh_handle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
    if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        log_amx("%s", error)
        return
	}
}

public sql_item_add_handle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        log_amx("%s", error)
        return
	}

	new id = data[0]
	// new lItemArrayId = data[1] NOT USED
	new lItemId = data[2]
	new lUserItemTime = data[3]
	new lItemCategory = data[4]
	new lAccountId = data[5]

	if(lAccountId != mg_reg_user_accountid_get(id))
		return

	new lUserItemSortId = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "LAST_INSERT_ID()"))

	new lUserItemArrayId

	lUserItemArrayId = ArrayPushCell(arrayUserItemSortId[id], lUserItemSortId)
	ArrayPushCell(arrayUserItemId[id], lItemId)
	ArrayPushCell(arrayUserItemTime[id], lUserItemTime)
	ArrayPushCell(arrayUserItemUsed[id], 0)
	ArrayPushCell(arrayUserItemCategory[id], lItemCategory)

	ExecuteForward(gForwardItemGiven, retValue, id, lItemId, lUserItemArrayId)
}

public sql_user_item_load_handle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
	new id = data[0]

	if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
		gItemsLoaded[id] = false
		mg_reg_user_sqlload_finished(id, MG_SQLID_ITEMS)
		log_amx("%s", error)
		return
	}

	while(SQL_MoreResults(Query))
	{
		ArrayPushCell(arrayUserItemSortId[id], SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemSortId")))
		ArrayPushCell(arrayUserItemId[id], SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemId")))
		ArrayPushCell(arrayUserItemUsed[id], SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemUsed")))
		ArrayPushCell(arrayUserItemTime[id], SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemTime")))
		ArrayPushCell(arrayUserItemCategory[id], SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "itemCategory")))

		SQL_NextRow(Query)
	}

	gItemsLoaded[id] = true
	mg_reg_user_sqlload_finished(id, MG_SQLID_ITEMS)
}

public sql_user_item_save_handle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
    if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        log_amx("%s^n [itemSortId = %d | itemId = %d | itemUsed = %d]", error, data[0], data[1], data[2])
        return
	}
}

public msgLoginUsername(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		menu_login_open(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)

		copy(gUsername[id], charsmax(gUsername[]), msg) 
	}
	
	menu_login_open(id)
	return PLUGIN_HANDLED
}

public msgLoginPassword(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		menu_login_open(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)
		copy(gPassword[id], charsmax(gPassword[]), msg) 
	}
	
	menu_login_open(id)
	return PLUGIN_HANDLED
}

public msgRegUsername(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		menu_register_open(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)

		if(strlen(msg) > MAX_USERNAME_LENGTH || strlen(msg) < MIN_USERNAME_LENGTH)
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_INVALIDSIZE", MAX_USERNAME_LENGTH, MIN_USERNAME_LENGTH)
			menu_register_open(id)
			return PLUGIN_HANDLED
		}

		copy(gUsername[id], charsmax(gUsername[]), msg) 
	}
	
	menu_register_open(id)
	return PLUGIN_HANDLED
}

public msgRegPassword(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		menu_register_open(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)
		
		if(strlen(msg) > MAX_PASSWORD_LENGTH || strlen(msg) < MIN_PASSWORD_LENGTH)
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_INVALIDSIZE", MAX_PASSWORD_LENGTH, MIN_PASSWORD_LENGTH)
			menu_register_open(id)
			return PLUGIN_HANDLED
		}

		copy(gPassword[id], charsmax(gPassword[]), msg) 
	}
	
	menu_register_open(id)
	return PLUGIN_HANDLED
}

public msgRegPasswordCheck(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		menu_register_open(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)
		copy(gPasswordCheck[id], charsmax(gPasswordCheck[]), msg) 
	}
	
	menu_register_open(id)
	return PLUGIN_HANDLED
}

public msgRegEMail(id)
{
	if(mg_reg_user_loading(id))
	{
		mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_USERSLOADING")
		menu_register_open(id)
		return PLUGIN_HANDLED
	}
	
	new msg[34]
	if(read_args(msg, charsmax(msg)))
	{
		remove_quotes(msg)

		if(strlen(msg) > MAX_EMAIL_LENGTH || strlen(msg) < MIN_EMAIL_LENGTH)
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_INVALIDSIZE", MAX_EMAIL_LENGTH, MIN_EMAIL_LENGTH)
			menu_register_open(id)
			return PLUGIN_HANDLED
		}

		if(contain(msg, "@") == -1 || contain(msg, ".") == -1)
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_INVALIDEMAIL")
			menu_register_open(id)
			return PLUGIN_HANDLED
		}

		copy(gEMail[id], charsmax(gEMail[]), msg) 
	}
	
	menu_register_open(id)
	return PLUGIN_HANDLED
}

public native_arrayid_item_get(plugin_id, param_num)
{
	if(get_param(1) != -1)
		set_param_byref(1, int:arrayItemId)

	if(get_param(2) != -1)
		set_param_byref(2, int:arrayItemName)
	
	if(get_param(3) != -1)
		set_param_byref(3, int:arrayItemDesc)

	if(get_param(4) != -1)
		set_param_byref(4, int:arrayItemCategory)

	if(get_param(5) != -1)
		set_param_byref(5, int:arrayItemTime)
}

public native_arrayid_useritem_get(plugin_id, param_num)
{
	new id = get_param(1)

	if(!is_user_connected(id))
		return
	
	if(get_param(2) != -1)
		set_param_byref(2, int:arrayUserItemSortId[id])
	
	if(get_param(3) != -1)
		set_param_byref(3, int:arrayUserItemId[id])

	if(get_param(4) != -1)
		set_param_byref(4, int:arrayUserItemTime[id])
	
	if(get_param(5) != -1)
		set_param_byref(5, int:arrayUserItemUsed[id])

	if(get_param(6) != -1)
		set_param_byref(6, int:arrayUserItemCategory[id])
}

public native_item_client_give(plugin_id, param_num)
{
	new id = get_param(1)
	new lItemId = get_param(2)
	new lArrayId = get_param(3)

	if(!mg_reg_user_loggedin(id))
		return false

	return userAddItem(id, lItemId, lArrayId)
}

public native_reg_open(plugin_id, param_num)
{
    new id = get_param(1)

    cmdReg(id)
    return true
}

public mg_fw_client_register_failed(id, errorType)
{
	switch(errorType)
	{
		case ERROR_SQL_ERROR:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_REGSQLERROR", "SQLERROR_REG")
			menu_register_open(id)
		}
		case ERROR_ACCOUNT_USED:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_REGUSERNAMETAKEN")
			menu_register_open(id)
		}
	}
}

public mg_fw_client_register_success(id)
{
	new lHashPassword[33]

	mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_REGSUCCESSFUL")
	mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINLOADING")

	hash_string(gPassword[id], Hash_Md5, lHashPassword, charsmax(lHashPassword))

	mg_reg_user_login(id, gUsername[id], lHashPassword)
}

public mg_fw_client_login_failed(id, errorType)
{
	switch(errorType)
	{
		case ERROR_ACCOUNT_NOT_FOUND:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINNOSUCHACCOUNT")
			menu_login_open(id)
		}
		case ERROR_SQL_ERROR:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINSQLERROR", "SQLERROR_LOGIN")
			menu_login_open(id)
		}
		case ERROR_ACCOUNT_USED:
		{
			mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINACCOUNTINUSE")
			menu_login_open(id)
		}
	}
}

public mg_fw_client_login_process(id, accountId)
{
	mg_reg_user_sqlload_start(id, MG_SQLID_ITEMS)
	userLoadItems(id, accountId)
	return PLUGIN_HANDLED
}

public mg_fw_client_login_success(id)
{
	mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGINSUCCESSFUL")
}

public mg_fw_client_logout(id)
{
	ArrayDestroy(arrayUserItemSortId[id])
	ArrayDestroy(arrayUserItemId[id])
	ArrayDestroy(arrayUserItemUsed[id])
	ArrayDestroy(arrayUserItemTime[id])
	ArrayDestroy(arrayUserItemCategory[id])

	gItemsLoaded[id] = false
	mg_fw_client_clean(id)
	mg_core_chatmessage_print(id, MG_CM_FIX, _, "%L", id, "REG_CHAT_LOGOUT")
}

public mg_fw_client_sql_save(id, accountId, saveType)
{
	if(!gItemsLoaded[id])
		return

	new lSqlTxt[120]
	new lArraySize = ArraySize(arrayUserItemSortId[id])
	new data[3]
	new lItemSortId
	new lItemUsed

	for(new i; i < lArraySize; i++)
	{
		lItemSortId = ArrayGetCell(arrayUserItemSortId[id], i)
		lItemUsed = ArrayGetCell(arrayUserItemUsed[id], i)

		data[0] = lItemSortId
		data[1] = ArrayGetCell(arrayItemId, i)
		data[2] = lItemUsed

		formatex(lSqlTxt, charsmax(lSqlTxt), "UPDATE ownedItemList SET (itemUsed, itemTime) VALUE (^"%d^", ^"%d^") WHERE itemSortId = ^"%d^"",
					lItemUsed, ArrayGetCell(arrayUserItemTime[id], i), lItemSortId)
		SQL_ThreadQuery(gSqlItemTuple, "sql_user_item_save_handle", lSqlTxt, data, sizeof(data))
	} // Kiváncsi vagyok, hogy ilyen mértékű sql használattal laggol majd-e a dolog
}

public mg_fw_client_clean(id)
{
	gUsername[id][0] = EOS
	gPassword[id][0] = EOS
	gPasswordCheck[id][0] = EOS
	gEMail[id][0] = EOS

	gMenuStoragePage[id] = 1
	gMenuItemArrayId[id] = -1
	gMenuActiveItemsPage[id] = 1
	gMenuActiveItemArrayId[id] = -1

	for(new i; i < sizeof(gMenuStoragePicks[]); i++)
	{
		gMenuStoragePicks[id][i] = -1
	}

	for(new i; i < sizeof(gMenuActiveItemsPicks[]); i++)
	{
		gMenuActiveItemsPicks[id][i] = -1
	}
}

checkUserSetinfoPW(id)
{
	new lSetinfoPW[33]
	get_user_info(id, "_pw", lSetinfoPW, charsmax(lSetinfoPW))

	if(!lSetinfoPW[0])
	{
		GenerateString(lSetinfoPW, 8)
		set_user_info(id, "_pw", lSetinfoPW)
		client_cmd(id, "setinfo ^"_pw^" ^"%s^"", lSetinfoPW)
	}
}

userAddItem(id, itemId, arrayId = -1)
{
	if(!mg_reg_user_loggedin(id))
		return false

	if(arrayId == -1)
	{
		arrayId = ArrayFindValue(arrayItemId, itemId)

		if(arrayId == -1)
			return false
	}

	new lSqlTxt[240]
	new len
	new data[6]
	new lAccountId = mg_reg_user_accountid_get(id)

	data[0] = id
	data[1] = arrayId
	data[2] = ArrayGetCell(arrayItemId, arrayId)
	data[3] = ArrayGetCell(arrayItemTime, arrayId) + get_systime()
	data[4] = ArrayGetCell(arrayItemCategory, arrayId)
	data[5] = lAccountId

	len = formatex(lSqlTxt, charsmax(lSqlTxt), "INSERT INTO ownedItemList ")
	len += formatex(lSqlTxt[len], charsmax(lSqlTxt) - len, "(itemId, itemTime, itemCategory, accountId) VALUES ")
	len += formatex(lSqlTxt[len], charsmax(lSqlTxt) - len, "(%d, %d, %d, %d);", data[2], data[3], data[4], lAccountId)
	len += formatex(lSqlTxt[len], charsmax(lSqlTxt) - len, "SELECT LAST_INSERT_ID();")
	SQL_ThreadQuery(gSqlItemTuple, "sql_user_item_add_handle", lSqlTxt, data, sizeof(data))
	
	return true
}

userLoadItems(id, accountId)
{
	arrayUserItemSortId[id] = ArrayCreate(1)
	arrayUserItemId[id] = ArrayCreate(1)
	arrayUserItemUsed[id] = ArrayCreate(1)
	arrayUserItemTime[id] = ArrayCreate(1)
	arrayUserItemCategory[id] = ArrayCreate(1)

	new lSqlTxt[120]
	new data[1]

	data[0] = id

	formatex(lSqlTxt, charsmax(lSqlTxt), "SELECT * FROM ownedItemList WHERE accountId = ^"%d^";", accountId)
	SQL_ThreadQuery(gSqlItemTuple, "sql_user_item_load_handle", lSqlTxt, data, sizeof(data))
}

loadValidItems()
{
	new lSqlTxt[24]

	formatex(lSqlTxt, charsmax(lSqlTxt), "SELECT * FROM itemList;")
	SQL_ThreadQuery(gSqlItemTuple, "sql_item_load_handle", lSqlTxt)
}

refreshUserItems()
{
	new lSqlTxt[120]

	formatex(lSqlTxt, charsmax(lSqlTxt), "DELETE FROM ownedItemList WHERE itemUsed = ^"1^" AND itemTime < ^"%d^";", get_systime())
	SQL_ThreadQuery(gSqlItemTuple, "sql_item_refresh_handle", lSqlTxt)
}

checkUserItemCategoryUsed(id, category)
{
	new lArraySize = ArraySize(arrayUserItemSortId[id])

	for(new i; i < lArraySize; i++)
	{
		if(checkUserItemActivity(id, i))
		{
			if(ArrayGetCell(arrayUserItemCategory[id], i) == category)
				return true
		}
	}

	return false
}

checkUserItemActivity(id, userItemArrayId)
{
	if(ArrayGetCell(arrayUserItemUsed[id], userItemArrayId) && ArrayGetCell(arrayUserItemTime[id], userItemArrayId) >= get_systime())
		return true
	
	return false
}

checkUserItemAccessibility(id, userItemArrayId)
{
	if(!ArrayGetCell(arrayUserItemUsed[id], userItemArrayId))
		return true
	
	return false
}

bool:getVisibleItems(id, Array:userItemIdArray, itemList[], itemPerPage, page)
{
	new count
	new lArrayStatus
	new lArraySize = ArraySize(userItemIdArray)
	new bool:lNextPage = false

	for(new i; i < lArraySize; i++)
	{
		if(checkUserItemAccessibility(id, i))
		{
			continue
		}

		if(count < itemPerPage*(page-1))
		{
			count++
			continue
		}

		if(ArrayFindValue(arrayItemId, ArrayGetCell(userItemIdArray, i)) == -1)
		{
			continue
		}

		if(lArrayStatus >= itemPerPage - 1)
		{
			for(++i; i < lArraySize; i++)
			{
				if(checkUserItemActivity(id, i))
				{
					continue
				}

				lNextPage = true
				break
			}
			break
		}

		itemList[lArrayStatus] = i
		lArrayStatus++
	}

	while(lArrayStatus <= itemPerPage - 1)
	{
		itemList[lArrayStatus] = -1
		lArrayStatus++
	}

	return lNextPage
}

bool:getActiveItems(id, Array:userItemIdArray, itemList[], itemPerPage, page)
{
	new count
	new lArrayStatus
	new lArraySize = ArraySize(userItemIdArray)
	new bool:lNextPage = false

	for(new i; i < lArraySize; i++)
	{
		if(!checkUserItemActivity(id, i))
		{
			continue
		}

		if(count < itemPerPage*(page-1))
		{
			count++
			continue
		}

		if(ArrayFindValue(arrayItemId, ArrayGetCell(userItemIdArray, i)) == -1)
		{
			continue
		}

		if(lArrayStatus >= itemPerPage - 1)
		{
			for(++i; i < lArraySize; i++)
			{
				if(!checkUserItemActivity(id, i))
				{
					continue
				}

				lNextPage = true
				break
			}
			break
		}

		itemList[lArrayStatus] = i
		lArrayStatus++
	}

	while(lArrayStatus <= itemPerPage - 1)
	{
		itemList[lArrayStatus] = -1
		lArrayStatus++
	}

	return lNextPage
}

unixToItemTime(unixTime, &Days = 0, &Hours = 0, &Minutes = 0, &Seconds = 0)
{
	Days = unixTime/86400
	Hours = (unixTime%86400)/3600
	Minutes = ((unixTime%86400)%3600)/60
	Seconds = (((unixTime%86400)%3600)%60)
}

userSetNextLanguage(id)
{
	new lUserLang[3]
	get_user_info(id, "lang", lUserLang, charsmax(lUserLang))

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

//By Exolent[jNr]
GenerateString(output[], const len)
{
	new choices[62] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWYZ0123456789"

	for(new i = 0; i < len; i++)
	{
		output[i] = choices[random(charsmax(choices))]
	}
    
	return len
}