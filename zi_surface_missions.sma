#include <amxmodx>
#include <amxconst>
#include <mg_missions_api>

#define PLUGIN "[MG] Missions Surface"
#define VERSION "1.0.0"
#define AUTHOR "Vieni"

#define MENUMISSIONS_IPP    4

#define MISSION_INSTANTFINISHPRICE		100

new Array:arrayMissionId
new Array:arrayMissionServerId
new Array:arrayMissionName
new Array:arrayMissionDesc
new Array:arrayMissionValueName
new Array:arrayMissionTargetValue
new Array:arrayMissionPrizeExp
new Array:arrayMissionPrizeMP

new gMenuMissionsPage[33]
new gMenuMissionsPicks[33][MENUMISSIONS_IPP]
new bool:gMenuMissionsShowFinished[33]
new bool:gMenuMissionsShowUnfinished[33]
new bool:gMenuMissionsNextPage[33]

new gMenuExactMissionArrayId[33]

new gUserNominatedMissions[33][3]

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

	register_menu("MR MissonList Menu", KEYSMENU, "menu_missionlist_handle")

    mg_missions_arrayid_get(int:arrayMissionId, int:arrayMissionServerId, int:arrayMissionName, int:arrayMissionDesc, int:arrayMissionValueName, 
            _, _, int:arrayMissionTargetValue, int:arrayMissionPrizeExp, int:arrayMissionPrizeMP)
}

public plugin_natives()
{
    register_native("zi_menu_missions_open", "native_menu_missions_open")
}

menu_missionlist_open(id, mPage = 1)
{
	if(!is_user_connected(id))
        return false
    
	new menu[500]
	new len
	new lMissionArrayIdList[MENUMISSIONS_IPP] = -1
	
	gMenuMissionsNextPage[id] = getVisibleMissions(id, arrayMissionId, lMissionArrayIdList, sizeof(lMissionArrayIdList), mPage)

	while(lMissionArrayIdList[0] == -1)
	{
		mPage -= 1
				
		if(mPage <= 1)
		{
			mPage = 1
			break
		}

		gMenuMissionsNextPage[id] =  getVisibleMissions(id, arrayUserItemId[id], lMissionArrayIdList, sizeof(lMissionArrayIdList), mPage)
	}

	new pickId = 4
	new lMissionName[64]
	new lMissionFinished
	new lMissionTargetValue
	new lMissionId

	len = mg_core_menu_title_create(id, "MR_TITLE_MISSIONLIST", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r  %L^n", id, "MR_MENU_MISSIONLIST0")
	len += formatex(menu[len], charsmax(menu) - len, "\r 1. %L^n", id, "MR_ MENU_MISSIONLIST1")
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, "\r 2. %L^n", id, "MR_MENU_MISSIONLIST2")
	len += formatex(menu[len], charsmax(menu) - len, "\r 3. %L^n", id, "MR_MENU_MISSIONLIST3")
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")

	for(new i; i < sizeof(lMissionArrayIdList); i++)
	{
		if(lMissionArrayIdList[i] == -1)
			break

		lMissionId = ArrayGetCell(arrayMissionId, lMissionArrayIdList[i])

		ArrayGetString(arrayMissionName, lMissionArrayIdList[i], lMissionName, charsmax(lMissionName))
		if(!(lMissionFinished = mg_missions_client_status_get(id, lMissionId)))
			lMissionTargetValue = ArrayGetCell(arrayMissionTargetValue, lMissionArrayIdList[i])
		
		if(lMissionFinished)
			len += formatex(menu[len], charsmax(menu) - len, "\r %d. \d%L \r[%L]^n", pickId, id, lMissionName, "MR_MENU_MISSIONFINISHED")
		else
			len += formatex(menu[len], charsmax(menu) - len, "\r %d. \w%L \r[%d/%d]^n", pickId, id, lMissionName, mg_missions_client_value_get(id, lMissionId), lTargetValue)

		pickId++
	}

	gMenuMissionsPicks[id] = lMissionArrayIdList

	if(pickId == 4)
	{
		len += formatex(menu[len], charsmax(menu) - len, "\y %L^n", id, "MR_MENU_NOAVAILABLEMISSION")
	}

	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	if(mPage <= 1)
		len += formatex(menu[len], charsmax(menu) - len, "\d						8. %L^n", id, "MR_MENU_BACK")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r						8. \w%L^n", id, "MR_MENU_BACK")
	
	if(!gMenuMissionsNextPage[id])
		len += formatex(menu[len], charsmax(menu) - len, "\d						9. %L^n", id, "MR_MENU_NEXT")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\r						9. \w%L^n", id, "MR_MENU_NEXT")
	
	len += formatex(menu[len], charsmax(menu) - len, "\r						0.\w %L", id, "MR_MENU_BACKSTEP")

	gMenuStoragePage[id] = mPage

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR MissonList Menu")
	return true
}

public menu_missionlist_handle(id, key)
{
	if(key >= 3 && key < 3+MENUMISSIONS_IPP)
	{
		new lMissionArrayId = -1

		lMissonArrayId = gMenuMissionsPicks[id][key-3]

		if(lUserItemArrayId == -1)
		{
			return PLUGIN_HANDLED
		}

		if(mg_missions_client_status_get(id, ArrayGetCell(arrayMissionId, lMissionArrayId)))
			// Küldi kész menü megnyitása
		else
			// Küldi kijelölés/vétel menü megnyitása

		return PLUGIN_HANDLED
	}

	switch(key)
	{
		case 0:
		{
			menu_mpshop_open(id)
		}
		case 1:
		{
			if(gMenuMissionsShowFinished[id] && !gMenuMissionsShowUnfinished[id] || !gMenuMissionsShowFinished[id] && gMenuMissionsShowUnfinished[id])
			{
				gMenuMissionsShowFinished[id] = true
				gMenuMissionsShowUnfinished[id] = true
			}
			else
				gMenuMissionsShowFinished[id] = !gMenuMissionsShowFinished[id]
			
			menu_missionlist_open(id)
		}
		case 2:
		{
			if(gMenuMissionsShowFinished[id] && !gMenuMissionsShowUnfinished[id] || !gMenuMissionsShowFinished[id] && gMenuMissionsShowUnfinished[id])
			{
				gMenuMissionsShowFinished[id] = true
				gMenuMissionsShowUnfinished[id] = true
			}
			else
				gMenuMissionsShowUnfinished[id] = !gMenuMissionsShowUnfinished[id]
			
			menu_missionlist_open(id)
		}
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

public menu_finishedmission_open(id, arrayId)
{
	new lMissionServerId = ArrayGetCell(arrayMissionServerId, arrayId)
	new lMissionName[64]
	new lMissionDesc[64]
	new lMissionPrizeExp = ArrayGetCell(arrayMissionPrizeExp, arrayId)
	new lMissionPrizeMP = ArrayGetCell(arrayMissionPrizeMP, arrayId)

	ArrayGetString(arrayMissionName, arrayId, lMissionName, charsmax(lMissionName))
	ArrayGetString(arrayMissionDesc, arrayId, lMissionDesc, charsmax(lMissionDesc))
	
	new menu[500]
	new len

	len = mg_core_menu_title_create(id, "MR_TITLE_ITEM", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, " [#%d]^n", arrayId+1)
	len += formatex(menu[len], charsmax(menu) - len, "	\y%L^n", id, lMissionName)
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "		\d%L^n", id, lMissionDesc)
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, " %L^n", id, "MR_MENU_ITEM0", lMissionPrizeMP)
	len += formatex(menu[len], charsmax(menu) - len, " %L^n", id, "MR_MENU_ITEM1", lMissionPrizeExp)
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\d						8. %L^n", id, "MR_MENU_BACK")
	len += formatex(menu[len], charsmax(menu) - len, "\d						9. %L^n", id, "MR_MENU_NEXT")
	len += formatex(menu[len], charsmax(menu) - len, "\d						0. %L^n", id, "MR_MENU_BACKSTEP")

	gMenuExactMissionArrayId[id] = arrayId

	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR FinishedMission Menu")

	return true
}

public menu_finishedmission_handle(id, key)
{
	switch(key)
	{
		case 7:
		{
			new lArraySize = ArraySize(arrayMissionId)
			new itemCount
			new i = lUserItemArrayId

			while(!isMenuMission(id, i))
			{
				if(itemCount >= lArraySize)
				{
					menu_missionlist_open(id, gMenuMissionsPage[id])
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

			if(mg_missions_client_status_get(id, ArrayGetCell(arrayMissionId, i)))
				menu_finishedmission_open(id, i)
			else
				menu_unfinishedmission_open(id, i)
		}
		case 8:
		{
			new lArraySize = ArraySize(arrayMissionId)
			new itemCount
			new i = lUserItemArrayId

			while(!isMenuMission(id, i))
			{
				if(itemCount >= lArraySize)
				{
					menu_missionlist_open(id, gMenuMissionsPage[id])
					return PLUGIN_HANDLED
				}

				if(i >= lArraySize)
				{
					i = 0
					continue
				}

				itemCount++
				i++
			}

			if(mg_missions_client_status_get(id, ArrayGetCell(arrayMissionId, i)))
				menu_finishedmission_open(id, i)
			else
				menu_unfinishedmission_open(id, i)
		}
		case 9:
		{
			menu_missionlist_open(id, gMenuMissionsPage[id])
		}
	}

	return PLUGIN_HANDLED
}

public menu_unfinishedmission_open(id, arrayId) // GOTTA REWRITE THIS SHIT
{
	new lMissionServerId = ArrayGetCell(arrayMissionServerId, arrayId)
	new lMissionName[64]
	new lMissionDesc[64]
	new lMissionPrizeExp = ArrayGetCell(arrayMissionPrizeExp, arrayId)
	new lMissionPrizeMP = ArrayGetCell(arrayMissionPrizeMP, arrayId)

	ArrayGetString(arrayMissionName, arrayId, lMissionName, charsmax(lMissionName))
	ArrayGetString(arrayMissionDesc, arrayId, lMissionDesc, charsmax(lMissionDesc))
	
	new menu[500]
	new len

	len = mg_core_menu_title_create(id, "MR_TITLE_ITEM", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, " [#%d]^n", arrayId+1)
	len += formatex(menu[len], charsmax(menu) - len, "	\y%L^n", id, lMissionName)
	len += formatex(menu[len], charsmax(menu) - len, "^n")
	len += formatex(menu[len], charsmax(menu) - len, "		\d%L^n", id, lMissionDesc)
	len += formatex(menu[len], charsmax(menu) - len, "\y				««¤===¤»»^n")
	len += formatex(menu[len], charsmax(menu) - len, " %L^n", id, "MR_MENU_ITEM0", lMissionPrizeMP)
	len += formatex(menu[len], charsmax(menu) - len, " %L^n", id, "MR_MENU_ITEM1", lMissionPrizeExp)
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")
	len += formatex(menu[len], charsmax(menu) - len, "\d						8. %L^n", id, "MR_MENU_BACK")
	len += formatex(menu[len], charsmax(menu) - len, "\d						9. %L^n", id, "MR_MENU_NEXT")
	len += formatex(menu[len], charsmax(menu) - len, "\d						0. %L^n", id, "MR_MENU_BACKSTEP")

	gMenuExactMissionArrayId[id] = arrayId

	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "MR FinishedMission Menu")

	return true
}

public menu_unfinishedmission_handle(id, key)
{
	switch(key)
	{
		case 7:
		{
			new lArraySize = ArraySize(arrayMissionId)
			new itemCount
			new i = lUserItemArrayId

			while(!isMenuMission(id, i))
			{
				if(itemCount >= lArraySize)
				{
					menu_missionlist_open(id, gMenuMissionsPage[id])
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

			if(mg_missions_client_status_get(id, ArrayGetCell(arrayMissionId, i)))
				menu_finishedmission_open(id, i)
			else
				menu_unfinishedmission_open(id, i)
		}
		case 8:
		{
			new lArraySize = ArraySize(arrayMissionId)
			new itemCount
			new i = lUserItemArrayId

			while(!isMenuMission(id, i))
			{
				if(itemCount >= lArraySize)
				{
					menu_missionlist_open(id, gMenuMissionsPage[id])
					return PLUGIN_HANDLED
				}

				if(i >= lArraySize)
				{
					i = 0
					continue
				}

				itemCount++
				i++
			}

			if(mg_missions_client_status_get(id, ArrayGetCell(arrayMissionId, i)))
				menu_finishedmission_open(id, i)
			else
				menu_unfinishedmission_open(id, i)
		}
		case 9:
		{
			menu_missionlist_open(id, gMenuMissionsPage[id])
		}
	}

	return PLUGIN_HANDLED
}

public native_menu_missions_open(plugin_id, param_num)
{
    new id = get_param(1)

    if(!is_user_connected(id))
        return false
    
    return menu_missionlist_open(id)
}

bool:getVisibleMissions(id, Array:missionIdArray, itemList[], itemPerPage, page)
{
	new count
	new lArrayStatus
	new lArraySize = ArraySize(missionIdArray)
	new bool:lNextPage = false

	for(new i; i < lArraySize; i++)
	{
		if(!isMenuMission)
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
				if(!isMenuMission)
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

bool:isMenuMission(id, arrayId)
{
	static lMissionStatus
	lMissionStatus = mg_missions_client_status_get(id, ArrayGetCell(arrayMissionId, arrayId))

	if(!(gMenuMissionsShowFinished[id] && gMenuMissionsShowUnfinished[id] || !gMenuMissionsShowFinished[id] && !gMenuMissionsShowUnfinished[id]))
	{
		if(!gMenuMissionsShowFinished[id] && lMissionStatus)
		{
			return false
		}
		
		if(!gMenuMissionsShowUnfinished[id] && !lMissionStatus)
		{
			return false
		}
	}
	
	return true
}