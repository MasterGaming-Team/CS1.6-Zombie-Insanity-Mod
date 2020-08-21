#include <amxmodx>
#include <amxconst>
#include <mg_missions_api>

#define PLUGIN "[MG] Missions Surface"
#define VERSION "1.0.0"
#define AUTHOR "Vieni"

#define MENUMISSIONS_IPP    4

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

	new pickId = 1
	new lMissionName[64]
	new lMissionFinished
	new lMissionTargetValue

	len = mg_core_menu_title_create(id, "MR_TITLE_MISSIONLIST", menu, charsmax(menu))
	len += formatex(menu[len], charsmax(menu) - len, "\d					-		-		-		-		-		-^n")

	for(new i; i < sizeof(lMissionArrayIdList); i++)
	{
		if(lMissionArrayIdList[i] == -1)
			break

		ArrayGetString(arrayMissionName, lMissionArrayIdList[i], lMissionName, charsmax(lMissionName))
		if(!(lMissionFinished = mg_missions_client_status_get(id, ArrayGetCell(arrayMissionId, lMissionArrayIdList[i]))))
			lMissionTargetValue = ArrayGetCell(arrayMissionTargetValue, lMissionArrayIdList[i])
		
		//CONTINUE BITCHfasrfwtaw
		asf
		if(retValue == ITEM_HANDLED)
			len += formatex(menu[len], charsmax(menu) - len, "\r %d. %L^n", pickId, id, lItemName)
		else
			len += formatex(menu[len], charsmax(menu) - len, "\d %d. %L^n", pickId, id, lItemName)

		pickId++
	}

	gMenuMissionsPicks[id] = lMissionArrayIdList

	if(pickId == 1)
	{
		len += formatex(menu[len], charsmax(menu) - len, "\y %L^n", id, "MR_MENU_NOAVAILABLEITEM")
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
	show_menu(id, KEYSMENU, menu, -1, "MR UserItems Menu")
	return true
}

public native_menu_missions_open(plugin_id, param_num)
{
    new id = get_param(1)

    if(!is_user_connected(id))
        return false
    
    return menu_missions_open(id)
}

bool:getVisibleMissions(id, Array:missionIdArray, itemList[], itemPerPage, page)
{
	new count
	new lArrayStatus
	new lArraySize = ArraySize(missionIdArray)
	new lMissionStatus
	new bool:lNextPage = false

	new bool:lUserSetting = !(gMenuMissionsShowFinished[id] && gMenuMissionsShowUnfinished[id] || !gMenuMissionsShowFinished[id] && !gMenuMissionsShowUnfinished[id])

	for(new i; i < lArraySize; i++)
	{
		lMissionStatus = ArrayGetCell(mg_missions_client_status_get(id, ArrayGetCell(arrayMissionId, i)))

		if(lUserSetting)
		{
			if(!gMenuMissionsShowFinished[id] && lMissionStatus)
			{
				continue
			}
			
			if(!gMenuMissionsShowUnfinished[id] && !lMissionStatus)
			{
				continue
			}
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
				if(lUserSetting)
				{
					if(!gMenuMissionsShowFinished[id] && lMissionStatus)
					{
						continue
					}
					
					if(!gMenuMissionsShowUnfinished[id] && !lMissionStatus)
					{
						continue
					}
				}

				lNextPage = true
				break
			}
			break
		}

		if(checkUserItemAccessibility(id, i))
		{
			continue
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