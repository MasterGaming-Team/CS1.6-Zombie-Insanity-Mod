#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <mg_core_const>

#define PLUGIN "[MG][ZI] Core plugin"
#define VERSIOn "1.0"
#define AUTHOr "Vieni"

#define flag_get(%1,%2) %1 & ((1 << (%2 & 31)))
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new gRespawnAsZombie, gUserZombie, gFirstZombie

new gMaxPlayers

new gRetValue
new gForwardInfectClient, gForwardCureClient, gForwardLastClient, gForwardSpawnClient

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    RegisterHamPlayer(Ham_Spawn, "hamFwPlayerSpawnPost", 1)
    RegisterHamPlayer(Ham_Killed, "hamFwPlayerKilledPost", 1)

    gMaxPlayers = get_maxplayers()

    gForwardInfectClient = CreateMultiForward("zi_fw_client_infect", ET_CONTINUE, FP_CELL, FP_CELL)
    gForwardCureClient = CreateMultiForward("zi_fw_client_cure", ET_CONTINUE, FP_CELL, FP_CELL)
    gForwardLastClient = CreateMultiForward("zi_fw_client_last", ET_CONTINUE, FP_CELL, FP_CELL)
    gForwardSpawnClient = CreateMultiForward("zi_fw_client_spawn", ET_CONTINUE, FP_CELL)
}

public plugin_natives()
{
    register_native("zi_client_zombie_is", "native_client_zombie_is")
    register_native("zi_client_zombie_last", "native_client_zombie_last")
    register_native("zi_human_count_get", "native_human_count_get")
    register_native("zi_zombie_count_get", "native_zombie_count_get")
}

public native_client_zombie_is(plugin_id, param_num)
{
    static id
    id = get_param(1)

    return flag_get(gUserZombie, id)
}

public native_client_zombie_last(plugin_id, param_num)

public native_human_count_get()
{
    return getHumanCount()
}

public native_zombie_count_get()
{
    return getZombieCount()
}

public hamFwPlayerSpawnPost(id)
{
    if(!is_user_alive(id))
        return

    ExecuteForward(gForwardSpawnClient, gRetValue, id)

    if(flag_get(gRespawnAsZombie, id))
    {
        userInfect(id)
        flag_unset(gRespawnAsZombie, id)
        return
    }

    userCure(id)
}

public hamFwPlayerKilledPost()
{
    checkLastPlayer()
}

InfectPlayer(id, attacker = 0)
{
	ExecuteForward(g_Forwards[FW_USER_INFECT_PRE], gRetValue, id, attacker)
	
	// One or more plugins blocked infection
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	ExecuteForward(g_Forwards[FW_USER_INFECT], g_ForwardResult, id, attacker)
	
	flag_set(g_IsZombie, id)
	
	if(getZombieCount() == 1)
		flag_set(gFirstZombie, id)
	else
		flag_unset(gFirstZombie, id)
	
	ExecuteForward(g_Forwards[FW_USER_INFECT_POST], g_ForwardResult, id, attacker)
	
	checkLastPlayer()
}

checkLastPlayer()
{
    new lHumanCount, lZombieCount, lHumanId, lZombieId

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_alive(i))
            continue
        
        if(flag_get(gUserZombie, id))
        {
            lZombieId = i
            lZombieCount++
        }
        else
        {
            lHumanId = i
            lHumanCount++
        }
    }

    if(lZombieCount == 1)
        ExecuteForward(gForwardLastClient, gRetValue, MG_ZI_FORWARD_ZOMBIE, gZombieId)
    
    if(lHumanCount == 1)
        ExecuteForward(gForwardLastClient, gRetValue, MG_ZI_FORWARD_HUMAN, lHumanId)
}

getZombieCount()
{
    new lCount

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(is_user_alive(i) && flag_get(gUserZombie, i))
            lCount++
    }

    return lCount
}

getHumanCount()
{
    new lCount

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(is_user_alive(i) && !flag_get(gUserZombie, i))   
            lCount++
    }

    return lCount
}