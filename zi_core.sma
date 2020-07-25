#include <amxmodx>
#include <amxmisc>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <mg_regsystem_api>
#include <mg_round_manager>
#include <reapi>
#include <sqlx>
#include <zi_core>

#define PLUGIN "[MG][ZI] Core plugin"
#define VERSION "1.0"
#define AUTHOR "Vieni"

#define TASKGAMEMODESTART   1

#define flag_get(%1,%2) %1 & ((1 << (%2 & 31)))
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new Array:arrayGamemodeId
new Array:arrayGamemodeName
new Array:arrayGamemodeType
new Array:arrayGamemodeAllowLaser
new Array:arrayGamemodeAllowShield
new Array:arrayGamemodeAllowInfect
new Array:arrayGamemodeAllowRespawn

new Array:arrayClassZombieId
new Array:arrayClassZombieDefSubClass
new Array:arrayClassZombieName
new Array:arrayClassZombieDesc
new Array:arrayClassZombieModel

new Array:arrayClassZombieSubParent
new Array:arrayClassZombieSubId
new Array:arrayClassZombieSubName
new Array:arrayClassZombieSubDesc
new Array:arrayClassZombieSubClaw
new Array:arrayClassZombieSubModel
new Array:arrayClassZombieSubBody
new Array:arrayClassZombieSubHealth
new Array:arrayClassZombieSubSpeed
new Array:arrayClassZombieSubGravity

new Array:arrayClassHumanId
new Array:arrayClassHumanName
new Array:arrayClassHumanDesc
new Array:arrayClassHumanModel
new Array:arrayClassHumanBody

new Array:arrayClassHeroId
new Array:arrayClassHeroName
new Array:arrayClassHeroTeam

new Handle:gSqlClassTuple

new bool:gAllowLaser, bool:gAllowShield, bool:gAllowInfect, bool:gAllowRespawn

new gUserClassZombieNext[33], gUserClassZombieSubNext[33], gUserClassHumanNext[33]
new gUserClassHero[33], gUserClassZombie[33], gUserClassZombieSub[33], gUserClassHuman[33]

new gGamemodeCurrent, gGamemodeNext

new retValue

new gMaxPlayers

new gForwardUserLast, gForwardUserSpawn
new gForwardUserInfect, gForwardUserCure, gForwardUserHeroisate
new gForwardGamemodeChosen, gForwardCountdownStart, gForwardGamemodeStart, gForwardGamemodeEnd
new gForwardClassZombieSubCritCheck

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    RegisterHamPlayer(Ham_Spawn, "fw_player_spawn_post", 1)
    RegisterHamPlayer(Ham_Killed, "fw_player_killed_post", 1)
    RegisterHamPlayer(Ham_TakeDamage, "fw_player_takedamage_pre")

    gMaxPlayers = get_maxplayers()
    
    gForwardUserSpawn = CreateMultiForward("zi_fw_client_spawn", ET_CONTINUE, FP_CELL)
    gForwardUserLast = CreateMultiForward("zi_fw_client_last", ET_CONTINUE, FP_CELL, FP_CELL)

    gForwardUserInfect = CreateMultiForward("zi_fw_client_infect", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
    gForwardUserCure = CreateMultiForward("zi_fw_client_cure", ET_CONTINUE, FP_CELL, FP_CELL)
    gForwardUserHeroisate = CreateMultiForward("zi_fw_client_heroisate", ET_CONTINUE, FP_CELL, FP_CELL)

    gForwardGamemodeChosen = CreateMultiForward("zi_fw_gamemode_chosen", ET_CONTINUE, FP_CELL)
    gForwardCountdownStart = CreateMultiForward("zi_fw_countdown_start", ET_CONTINUE, FP_CELL)
    gForwardGamemodeStart = CreateMultiForward("zi_fw_gamemode_start", ET_CONTINUE, FP_CELL)
    gForwardGamemodeEnd = CreateMultiForward("zi_fw_gamemode_end", ET_CONTINUE, FP_CELL)

    gForwardClassZombieSubCritCheck = CreateMultiForward("zi_fw_class_zombiesub_critcheck", ET_STOP, FP_CELL, FP_CELL)
}

public plugin_natives()
{
    gSqlClassTuple = SQL_MakeDbTuple("127.0.0.1", "MG_User", "fKj4zbI0wxwPoFzU", "cs_zinsanity")

    arrayGamemodeId = ArrayCreate(1)
    arrayGamemodeName = ArrayCreate(64)
    arrayGamemodeType = ArrayCreate(1)
    arrayGamemodeAllowLaser = ArrayCreate(1)
    arrayGamemodeAllowShield = ArrayCreate(1)
    arrayGamemodeAllowInfect = ArrayCreate(1)
    arrayGamemodeAllowRespawn = ArrayCreate(1)

    arrayClassZombieId = ArrayCreate(1)
    arrayClassZombieDefSubClass = ArrayCreate(1)
    arrayClassZombieName = ArrayCreate(64)
    arrayClassZombieDesc = ArrayCreate(64)
    arrayClassZombieModel = ArrayCreate(64)

    arrayClassZombieSubParent = ArrayCreate(1)
    arrayClassZombieSubId = ArrayCreate(1)
    arrayClassZombieSubName = ArrayCreate(64)
    arrayClassZombieSubDesc = ArrayCreate(64)
    arrayClassZombieSubClaw = ArrayCreate(64)
    arrayClassZombieSubModel = ArrayCreate(64)
    arrayClassZombieSubBody = ArrayCreate(1)
    arrayClassZombieSubHealth = ArrayCreate(1)
    arrayClassZombieSubSpeed = ArrayCreate(1)
    arrayClassZombieSubGravity = ArrayCreate(1)

    arrayClassHumanId = ArrayCreate(1)
    arrayClassHumanName = ArrayCreate(64)
    arrayClassHumanDesc = ArrayCreate(64)
    arrayClassHumanModel = ArrayCreate(64)
    arrayClassHumanBody = ArrayCreate(1)

    arrayClassHeroId = ArrayCreate(1)
    arrayClassHeroName = ArrayCreate(64)
    arrayClassHeroTeam = ArrayCreate(1)

    register_native("zi_core_arrayid_gamemode_get", "native_arrayid_gamemode_get")
    register_native("zi_core_arrayid_zombie_get", "native_arrayid_zombie_get")
    register_native("zi_core_arrayid_zombiesub_get", "native_arrayid_zombiesub_get")
    register_native("zi_core_arrayid_human_get", "native_arrayid_human_get")
    register_native("zi_core_arrayid_hero_get", "native_arrayid_hero_get")
    
    register_native("zi_core_allow_laser", "native_allow_laser")
    register_native("zi_core_allow_shield", "native_allow_shield")
    register_native("zi_core_allow_infect", "native_allow_infect")
    register_native("zi_core_allow_respawn", "native_allow_respawn")

    register_native("zi_core_gamemode_reg", "native_gamemode_reg")

    register_native("zi_core_class_zombie_reg", "native_class_zombie_reg")
    register_native("zi_core_class_zombiesub_reg", "native_class_zombiesub_reg")
    register_native("zi_core_class_human_reg", "native_class_human_reg")
    register_native("zi_core_class_hero_reg", "native_class_hero_reg")

    register_native("zi_core_class_zombie_arrayslot_get", "native_class_zombie_arrayslot_get")
    register_native("zi_core_class_zombiesub_arrayslot_get", "native_class_zombiesub_arrayslot_get")
    register_native("zi_core_class_human_arrayslot_get", "native_class_human_arrayslot_get")
    register_native("zi_core_class_hero_arrayslot_get", "native_class_hero_arrayslot_get")

    register_native("zi_core_client_last", "native_client_last")

    register_native("zi_core_client_zombiesub_available", "native_client_zombiesub_available")

    register_native("zi_core_client_zombie_get", "native_client_zombie_get")
    register_native("zi_core_client_zombiesub_get", "native_client_zombiesub_get")
    register_native("zi_core_client_human_get", "native_client_human_get")
    register_native("zi_core_client_hero_get", "native_client_hero_get")

    register_native("zi_core_client_zombie_set", "native_client_zombie_set")
    register_native("zi_core_client_human_set", "native_client_human_set")

    register_native("zi_core_client_infect", "native_client_infect")
    register_native("zi_core_client_cure", "native_client_cure")
    register_native("zi_core_client_heroisate", "native_client_heroisate")
}

public start_gamemode()
{
    remove_task(TASKGAMEMODESTART)

    gGamemodeCurrent = gGamemodeNext
    gGamemodeNext = ZI_GAMEMODE_NONE

    if(gAllowRespawn)
        set_cvar_float("mp_forcerespawn", 4.0)
    else
        set_cvar_num("mp_forcerespawn", 0)

    ExecuteForward(gForwardGamemodeStart, retValue, gGamemodeCurrent)
}

public sql_class_load_handle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
    new id = data[0]
    new accountId = data[1]

    if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        log_amx("%s", error)
        mg_reg_user_sqlload_finished(id, MG_SQLID_ZICLASSES)
        return
	}
	
    if(SQL_NumRows(Query) < 1)
	{
        new lSqlText[120], len
		
        formatex(lSqlText, charsmax(lSqlText), "INSERT INTO classes ")
        len += formatex(lSqlText[len], charsmax(lSqlText) - len, "(accountId, ZClass, ZSubClass, HClass) ")
        len += formatex(lSqlText[len], charsmax(lSqlText) - len, "VALUE ")
        len += formatex(lSqlText[len], charsmax(lSqlText) - len, "(^"%d^", ^"%d^", ^"%d^", ^"%d^");",
                    accountId, gUserClassZombieNext[id], gUserClassZombieSubNext[id], gUserClassHumanNext[id])
        SQL_ThreadQuery(gSqlClassTuple, "sql_class_load_handle", lSqlText)

        mg_reg_user_sqlload_finished(id, MG_SQLID_ZICLASSES)
        return
	}

    new lClassZombieId, lClassZombieSubId, lClassHumanId

    lClassZombieId = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ZClass"))
    lClassZombieSubId = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ZSubClass"))
    lClassHumanId = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "HClass"))

    if(ArrayFindValue(arrayClassZombieId, lClassZombieId) == -1 || ArrayFindValue(arrayClassZombieSubId, lClassZombieSubId) == -1)
    {
        lClassZombieId = ZI_ZMCLASS_NORMAL
        lClassZombieSubId = ZI_ZMSUBCLASS_NORMAL1
    }

    if(ArrayFindValue(arrayClassHumanId, lClassHumanId) == -1)
    {
        lClassHumanId = ZI_HMCLASS_NORMAL
    }

    gUserClassZombieNext[id] = lClassZombieId
    gUserClassZombieSubNext[id] = lClassZombieSubId
    gUserClassHumanNext[id] = lClassHumanId

    mg_reg_user_sqlload_finished(id, MG_SQLID_ZICLASSES)
}

public sql_class_create_handle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
    if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        log_amx("%s", error)
        return
	}
}

public sql_class_save_handle(FailState, Handle:Query, error[], errorcode, data[], datasize, Float:fQueueTime)
{
    if(FailState == TQUERY_CONNECT_FAILED || FailState == TQUERY_QUERY_FAILED)
	{
        log_amx("%s", error)
        return
	}
}

public native_arrayid_gamemode_get(plugin_id, param_num)
{
    if(get_param(1) != -1)
        set_param_byref(1, int:arrayGamemodeId)
    
    if(get_param(2) != -1)
        set_param_byref(2, int:arrayGamemodeName)
    
    if(get_param(3) != -1)
        set_param_byref(3, int:arrayGamemodeType)
    
    if(get_param(4) != -1)
        set_param_byref(4, int:arrayGamemodeAllowLaser)

    if(get_param(5) != -1)
        set_param_byref(5, int:arrayGamemodeAllowShield)

    if(get_param(6) != -1)
        set_param_byref(6, int:arrayGamemodeAllowInfect)

    if(get_param(7) != -1)
        set_param_byref(7, int:arrayGamemodeAllowRespawn)
}

public native_arrayid_zombie_get(plugin_id, param_num)
{
    if(get_param(1) != -1)
        set_param_byref(1, int:arrayClassZombieId)

    if(get_param(2) != -1)
        set_param_byref(2, int:arrayClassZombieDefSubClass)
    
    if(get_param(3) != -1)
        set_param_byref(3, int:arrayClassZombieName)
    
    if(get_param(4) != -1)
        set_param_byref(4, int:arrayClassZombieDesc)
    
    if(get_param(5) != -1)
        set_param_byref(5, int:arrayClassZombieModel)
}

public native_arrayid_zombiesub_get(plugin_id, param_num)
{
    if(get_param(1) != -1)
        set_param_byref(1, int:arrayClassZombieSubParent)
    
    if(get_param(2) != -1)
        set_param_byref(2, int:arrayClassZombieSubId)
    
    if(get_param(3) != -1)
        set_param_byref(3, int:arrayClassZombieSubName)
    
    if(get_param(4) != -1)
        set_param_byref(4, int:arrayClassZombieSubDesc)

    if(get_param(5) != -1)
        set_param_byref(5, int:arrayClassZombieSubClaw)

    if(get_param(6) != -1)
        set_param_byref(6, int:arrayClassZombieSubModel)

    if(get_param(7) != -1)
        set_param_byref(7, int:arrayClassZombieSubBody)

    if(get_param(8) != -1)
        set_param_byref(8, int:arrayClassZombieSubHealth)

    if(get_param(9) != -1)
        set_param_byref(9, int:arrayClassZombieSubSpeed)
    
    if(get_param(10) != -1)
        set_param_byref(10, int:arrayClassZombieSubGravity)
}

public native_arrayid_human_get(plugin_id, param_num)
{
    if(get_param(1) != -1)
        set_param_byref(1, int:arrayClassHumanId)
    
    if(get_param(2) != -1)
        set_param_byref(2, int:arrayClassHumanName)
    
    if(get_param(3) != -1)
        set_param_byref(3, int:arrayClassHumanDesc)
    
    if(get_param(4) != -1)
        set_param_byref(4, int:arrayClassHumanModel)

    if(get_param(5) != -1)
        set_param_byref(5, int:arrayClassHumanBody)
}

public native_arrayid_hero_get(plugin_id, param_num)
{
    if(get_param(1) != -1)
        set_param_byref(1, int:arrayClassHeroId)
    
    if(get_param(2) != -1)
        set_param_byref(2, int:arrayClassHeroName)
    
    if(get_param(3) != -1)
        set_param_byref(3, int:arrayClassHeroTeam)
}

public native_allow_laser(plugin_id, param_num)
{
    return gAllowLaser
}

public native_allow_shield(plugin_id, param_num)
{
    return gAllowShield
}

public native_allow_infect(plugin_id, param_num)
{
    return gAllowInfect
}

public native_allow_respawn(plugin_id, param_num)
{
    return gAllowRespawn
}

public native_gamemode_reg(plugin_id, param_num)
{
    new lGamemodeId = get_param(1)

    if(ArrayFindValue(arrayGamemodeId, lGamemodeId) != -1)
    {
        log_amx("[GAMEMODEREG] Gamemode's already registered! (%d)", lGamemodeId)
        return ZI_GAMEMODE_NONE
    }

    new lGamemodeName[64], lGamemodeType, lGamemodeAllowLaser, lGamemodeAllowShield, lGamemodeAllowInfect, lGamemodeAllowRespawn

    get_string(2, lGamemodeName, charsmax(lGamemodeName))

    lGamemodeType = get_param(3)
    lGamemodeAllowLaser = get_param(4)
    lGamemodeAllowShield = get_param(5)
    lGamemodeAllowInfect = get_param(6)
    lGamemodeAllowRespawn = get_param(7)

    ArrayPushCell(arrayGamemodeId, lGamemodeId)
    ArrayPushString(arrayGamemodeName, lGamemodeName)
    ArrayPushCell(arrayGamemodeType, lGamemodeType)
    ArrayPushCell(arrayGamemodeAllowLaser, lGamemodeAllowLaser)
    ArrayPushCell(arrayGamemodeAllowShield, lGamemodeAllowShield)
    ArrayPushCell(arrayGamemodeAllowInfect, lGamemodeAllowInfect)
    ArrayPushCell(arrayGamemodeAllowRespawn, lGamemodeAllowRespawn)

    return lGamemodeId
}

public native_class_zombie_reg(plugin_id, param_num)
{
    new lClassId = get_param(1)

    if(ArrayFindValue(arrayClassZombieId, lClassId) != -1)
    {
        log_amx("[CLASSZOMBIEREG] Class is already registered! (%d)", lClassId)
        return ZI_CLASS_NONE
    }

    new lClassDefSubClass, lClassName[64], lClassDesc[64], lClassModel[64]

    lClassDefSubClass = get_param(2)
    get_string(3, lClassName, charsmax(lClassName))
    get_string(4, lClassDesc, charsmax(lClassDesc))
    get_string(5, lClassModel, charsmax(lClassModel))

    ArrayPushCell(arrayClassZombieId, lClassId)
    ArrayPushCell(arrayClassZombieDefSubClass, lClassDefSubClass)
    ArrayPushString(arrayClassZombieName, lClassName)
    ArrayPushString(arrayClassZombieDesc, lClassDesc)
    ArrayPushString(arrayClassZombieModel, lClassModel)

    return lClassId
}

public native_class_zombiesub_reg(plugin_id, param_num)
{
    new lParentClassId = get_param(1)
    new lClassId = get_param(2)
    
    if(ArrayFindValue(arrayClassZombieId, lParentClassId) == -1)
    {
        log_amx("[CLASSZOMBIESUBREG] Parent class is not registered! (%d)", lParentClassId)
        return ZI_CLASS_NONE
    }

    if(ArrayFindValue(arrayClassZombieSubId, lClassId) != -1)
    {
        log_amx("[CLASSZOMBIESUBREG] Class is already registered! (%d)", lClassId)
        return ZI_CLASS_NONE
    }

    new lClassName[64], lClassDesc[64], lClassClaw[64], lClassModel[64], lClassBody, lClassHealth, Float:lClassSpeed, Float:lClassGravity

    get_string(3, lClassName, charsmax(lClassName))
    get_string(4, lClassDesc, charsmax(lClassDesc))
    get_string(5, lClassClaw, charsmax(lClassClaw))
    get_string(6, lClassModel, charsmax(lClassModel))

    lClassBody = get_param(7)
    lClassHealth = get_param(8)
    lClassSpeed = get_param_f(9)
    lClassGravity = get_param_f(10)

    if(!lClassModel[0])
        ArrayGetString(arrayClassZombieModel, ArrayFindValue(arrayClassZombieId, lParentClassId), lClassName, charsmax(lClassName))

    ArrayPushCell(arrayClassZombieSubParent, lParentClassId)
    ArrayPushCell(arrayClassZombieId, lClassId)
    ArrayPushString(arrayClassZombieName, lClassName)
    ArrayPushString(arrayClassZombieDesc, lClassDesc)
    ArrayPushString(arrayClassZombieSubClaw, lClassClaw)
    ArrayPushString(arrayClassZombieModel, lClassModel)
    ArrayPushCell(arrayClassZombieSubBody, lClassBody)
    ArrayPushCell(arrayClassZombieSubHealth, lClassHealth)
    ArrayPushCell(arrayClassZombieSubSpeed, lClassSpeed)
    ArrayPushCell(arrayClassZombieSubGravity, lClassGravity)

    return lClassId
}

public native_class_human_reg(plugin_id, param_num)
{
    new lClassId = get_param(1)

    if(ArrayFindValue(arrayClassHumanId, lClassId) != -1)
    {
        log_amx("[CLASSHUMANREG] Class's already registered! (%d)", lClassId)
        return ZI_CLASS_NONE
    }

    new lClassName[64], lClassDesc[64], lClassModel[64], lClassBody

    get_string(2, lClassName, charsmax(lClassName))
    get_string(3, lClassDesc, charsmax(lClassDesc))
    get_string(4, lClassModel, charsmax(lClassModel))

    lClassBody = get_param(5)
    
    ArrayPushCell(arrayClassHumanId, lClassId)
    ArrayPushString(arrayClassHumanName, lClassName)
    ArrayPushString(arrayClassZombieDesc, lClassDesc)
    ArrayPushString(arrayClassHumanModel, lClassModel)
    ArrayPushCell(arrayClassHumanBody, lClassBody)

    return lClassId
}

public native_class_hero_reg(plugin_id, param_num)
{
    new lClassId = get_param(1)
    
    if(ArrayFindValue(arrayClassHeroId, lClassId) != -1)
    {
        log_amx("[CLASSHEROREG] Class's already registered! (%d)", lClassId)
        return ZI_CLASS_NONE
    }

    new lClassName[64], lClassTeam
    
    get_string(2, lClassName, charsmax(lClassName))
    lClassTeam = get_param(3)

    ArrayPushCell(arrayClassHeroId, lClassId)
    ArrayPushString(arrayClassHeroName, lClassName)
    ArrayPushCell(arrayClassHeroTeam, lClassTeam)

    return lClassId
}

public native_class_zombie_arrayslot_get(plugin_id, param_num)
{
    new lClassId = get_param(1)
    new lArrayId = ArrayFindValue(arrayClassZombieId, lClassId)

    if(lArrayId == -1)
        log_amx("[CLASSZOMBIEARRAYSLOTGET] Class is not found! (%d)", lClassId)

    return lArrayId
}

public native_class_zombiesub_arrayslot_get(plugin_id, param_num)
{
    new lClassId = get_param(1)
    new lArrayId = ArrayFindValue(arrayClassZombieSubId, lClassId)

    if(lArrayId == -1)
        log_amx("[CLASSZOMBIESUBARRAYSLOTGET] Class is not found! (%d)", lClassId)

    return lArrayId
}

public native_class_human_arrayslot_get(plugin_id, param_num)
{
    new lClassId = get_param(1)
    new lArrayId = ArrayFindValue(arrayClassHumanId, lClassId)

    if(lArrayId == -1)
        log_amx("[CLASSHUMANARRAYSLOTGET] Class is not found! (%d)", lClassId)

    return lArrayId
}

public native_class_hero_arrayslot_get(plugin_id, param_num)
{
    new lClassId = get_param(1)
    new lArrayId = ArrayFindValue(arrayClassHeroId, lClassId)

    if(lArrayId == -1)
        log_amx("[CLASSHEROARRAYSLOTGET] Class is not found! (%d)", lClassId)

    return lArrayId
}

public native_client_last(plugin_id, param_num)
{
    new id = get_param(1)
    new lTeam = get_param(2)

    return isLastPlayer(id, CsTeams:lTeam)
}

public native_client_zombiesub_available(plugin_id, param_num)
{
    static id, lClassId
    id = get_param(1)
    lClassId = get_param(2)

    ExecuteForward(gForwardClassZombieSubCritCheck, retValue, id, lClassId)

    if(retValue == PLUGIN_HANDLED)
        return true
    
    return false
}

public native_client_zombie_get(plugin_id, param_num)
{
    static id, lNext
    id = get_param(1)
    lNext = get_param(2)

    return getPlayerZombie(id, lNext)
}

public native_client_zombiesub_get(plugin_id, param_num)
{
    static id, lNext
    id = get_param(1)
    lNext = get_param(2)

    return getPlayerZombieSub(id, lNext)
}

public native_client_human_get(plugin_id, param_num)
{
    static id, lNext
    id = get_param(1)
    lNext = get_param(2)

    return getPlayerHuman(id, lNext)
}

public native_client_hero_get(plugin_id, param_num)
{
    static id
    id = get_param(1)

    return getPlayerHero(id)
}

public native_client_zombie_set(plugin_id, param_num)
{
    static id, lClassId, lClassSubId, lCurrent

    id = get_param(1)
    lClassId = get_param(2)
    lClassSubId = get_param(3)
    lCurrent = get_param(4)

    if(!lCurrent)
    {
        if(lClassId == ZI_CLASS_NONE && lClassSubId != ZI_CLASS_NONE)
        {
            lClassId = ArrayGetCell(arrayClassZombieSubParent, ArrayFindValue(arrayClassZombieSubId, lClassSubId))
        }
        gUserClassZombieNext[id] = lClassId
        gUserClassZombieSubNext[id] = lClassSubId
        return true
    }

    if(lClassId == ZI_CLASS_NONE)
    {
        if(lClassSubId != ZI_CLASS_NONE)
        {
            lClassId = ArrayGetCell(arrayClassZombieSubParent, ArrayFindValue(arrayClassZombieSubId, lClassSubId))
        }
        else
        {
            lClassId = gUserClassZombieNext[id]
            lClassSubId = gUserClassZombieSubNext[id]
        }
    }

    return infectPlayer(id, id, lClassId, lClassSubId)
}

public native_client_human_set(plugin_id, param_num)
{
    static id, lClassId, lCurrent

    id = get_param(1)
    lClassId = get_param(2)
    lCurrent = get_param(3)

    if(!lCurrent)
    {
        gUserClassHumanNext[id] = lClassId
        return true
    }

    if(lClassId == ZI_CLASS_NONE)
    {
        lClassId = gUserClassHumanNext[id]
    }

    return curePlayer(id, id, lClassId)
}

public native_client_infect(plugin_id, param_num)
{
    static victim, attacker
    victim = get_param(1)
    attacker = get_param(2)

    if(!attacker)
        attacker = victim

    return infectPlayer(victim, attacker, gUserClassZombieNext[victim], gUserClassZombieSubNext[victim])
}

public native_client_cure(plugin_id, param_num)
{
    static victim, attacker
    victim = get_param(1)
    attacker = get_param(2)

    if(!attacker)
        attacker = victim
    
    return curePlayer(victim, attacker, gUserClassHumanNext[victim])
}

public native_client_heroisate(plugin_id, param_num)
{
    static id, lClassId
    id = get_param(1)
    lClassId = get_param(2)

    return heroisatePlayer(id, lClassId)
}

public mg_fw_client_login_process(id, accountId)
{
    new lSqlTxt[70], data[2]
    data[0] = id
    data[1] = accountId

    mg_reg_user_sqlload_start(id, MG_SQLID_ZICLASSES)

    formatex(lSqlTxt, charsmax(lSqlTxt), "SELECT * FROM classes WHERE accountId = ^"%d^";", accountId)
    SQL_ThreadQuery(gSqlClassTuple, "sql_class_load_handle", lSqlTxt, data, sizeof(data))

    return PLUGIN_HANDLED
}

public mg_fw_client_sql_save(id, accountId, saveType)
{
    if(saveType == SQL_SAVETYPE_LOGOUT)
    {
        new lSqlText[120], len

        len += formatex(lSqlText[len], charsmax(lSqlText) - len, "UPDATE classes SET")
        len += formatex(lSqlText[len], charsmax(lSqlText) - len, " ZClass = ^"%d^", ZSubClass = ^"%d^", HClass = ^"%d^"",
                        gUserClassZombieNext[id], gUserClassZombieSubNext[id], gUserClassHumanNext[id])
        len += formatex(lSqlText[len], charsmax(lSqlText) - len, " WHERE accountId=^"%d^";", accountId)
        SQL_ThreadQuery(gSqlClassTuple, "sql_class_save_handle", lSqlText)

        mg_fw_client_clean(id)
    }
}

public mg_fw_client_clean(id)
{
    gUserClassZombieNext[id] = ZI_CLASS_NONE
    gUserClassZombieSubNext[id] = ZI_CLASS_NONE
    gUserClassHumanNext[id] = ZI_CLASS_NONE
    gUserClassHero[id] = ZI_CLASS_NONE
    gUserClassZombie[id] = ZI_CLASS_NONE
    gUserClassZombieSub[id] = ZI_CLASS_NONE
    gUserClassHuman[id] = ZI_CLASS_NONE
}

public mg_fw_round_start_post()
{
    startGamemodeProcess()
}

public mg_fw_round_end_post()
{
    remove_task(TASKGAMEMODESTART)

    new lGamemodeCurrent = gGamemodeCurrent
    gGamemodeCurrent = ZI_GAMEMODE_NONE
    gGamemodeNext = ZI_GAMEMODE_NONE

    set_cvar_float("mp_forcerespawn", 0.0001)

    rg_balance_teams()

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_alive(i))
            continue
        
        curePlayer(i, i, gUserClassHumanNext[i])
    }

    ExecuteForward(gForwardGamemodeEnd, retValue, lGamemodeCurrent)
}

public fw_player_spawn_post(id)
{
    if(gGamemodeCurrent)
    {
        ExecuteForward(gForwardUserSpawn, retValue, id)

        if(CsTeams:retValue == ZI_TEAM_ZOMBIE)
            infectPlayer(id, id, gUserClassZombieNext[id], gUserClassZombieSubNext[id])
        else
            curePlayer(id, id, gUserClassHumanNext[id])
    }
    else
        curePlayer(id, id, gUserClassHumanNext[id])
}

public fw_player_killed_post(victim, attacker, shouldgib)
{
    checkLastPlayer()
}

public fw_player_takedamage_pre(victim, inflictior, attacker, Float:damage, damagebits)
{
    if(gGamemodeCurrent == ZI_GAMEMODE_NONE)
    {
        SetHamParamFloat(4, 0.0)
        return HAM_IGNORED
    }

    if(getPlayerHero(victim) || getPlayerZombie(victim))
        return HAM_IGNORED
    
    if(isLastPlayer(victim, ZI_TEAM_HUMAN) || !gAllowInfect)
        return HAM_IGNORED
    
    if(zi_client_armor_get(victim) && gAllowShield)
    {
        zi_client_armor_damage(victim, damage)
        return HAM_SUPERCEDE
    }

    if(gAllowInfect)
    {
        infectPlayer(victim, attacker, gUserClassZombieNext[victim], gUserClassZombieSubNext[victim])
        return HAM_SUPERCEDE
    }

    return HAM_IGNORED
}

startGamemodeProcess()
{
    remove_task(TASKGAMEMODESTART)
    chooseGamemode()
    set_task(10.0, "start_gamemode", TASKGAMEMODESTART)
    ExecuteForward(gForwardCountdownStart, retValue, gGamemodeNext)
}

chooseGamemode()
{
    static lGamemodeState

    switch(lGamemodeState)
    {
        case ZI_GMTYPE_NONE:
        {
            static modeBefore

            gGamemodeNext = getRandomGamemode(ZI_GMTYPE_NORMAL, modeBefore)
            modeBefore = gGamemodeNext

            lGamemodeState = ZI_GMTYPE_NORMAL
        }
        case ZI_GMTYPE_NORMAL:
        {
            static modeBefore

            gGamemodeNext = getRandomGamemode(ZI_GMTYPE_NORMAL, modeBefore)
            modeBefore = gGamemodeNext

            lGamemodeState = ZI_GMTYPE_MULTIPLE
        }
        case ZI_GMTYPE_MULTIPLE:
        {
            static modeBefore
            
            gGamemodeNext = getRandomGamemode(ZI_GMTYPE_MULTIPLE, modeBefore)
            modeBefore = gGamemodeNext

            lGamemodeState = ZI_GMTYPE_HERO
        }
        case ZI_GMTYPE_HERO:
        {
            static modeBefore
            
            gGamemodeNext = getRandomGamemode(ZI_GMTYPE_HERO, modeBefore)
            modeBefore = gGamemodeNext

            lGamemodeState = ZI_GMTYPE_ARMAGEDDON
        }
        case ZI_GMTYPE_ARMAGEDDON:
        {
            static modeBefore
            
            gGamemodeNext = getRandomGamemode(ZI_GMTYPE_ARMAGEDDON, modeBefore)
            modeBefore = gGamemodeNext

            lGamemodeState = ZI_GMTYPE_NONE
        }
    }

    ExecuteForward(gForwardGamemodeChosen, retValue, gGamemodeNext)
}

getRandomGamemode(type = ZI_GMTYPE_NONE, modeBefore = -1)
{
    new lArraySize = ArraySize(arrayGamemodeType)
    new Array:lArrayGamemodeList
    new lGamemodeId

    lArrayGamemodeList = ArrayCreate(1)

    switch(type)
    {
        case ZI_GMTYPE_NORMAL:
        {
            for(new i; i < lArraySize; i++)
            {
                lGamemodeId = ArrayGetCell(arrayGamemodeId, i)

                if(lGamemodeId == modeBefore && lArraySize > 1)
                    continue

                if(ArrayGetCell(arrayGamemodeType, i) == ZI_GMTYPE_NORMAL)
                    ArrayPushCell(lArrayGamemodeList, lGamemodeId)
            }
        }
        case ZI_GMTYPE_MULTIPLE:
        {
            for(new i; i < lArraySize; i++)
            {
                lGamemodeId = ArrayGetCell(arrayGamemodeId, i)

                if(lGamemodeId == modeBefore && lArraySize > 1)
                    continue

                if(ArrayGetCell(arrayGamemodeType, i) == ZI_GMTYPE_MULTIPLE)
                    ArrayPushCell(lArrayGamemodeList, lGamemodeId)
            }
        }
        case ZI_GMTYPE_HERO:
        {
            for(new i; i < lArraySize; i++)
            {
                lGamemodeId = ArrayGetCell(arrayGamemodeId, i)

                if(lGamemodeId == modeBefore && lArraySize > 1)
                    continue

                if(ArrayGetCell(arrayGamemodeType, i) == ZI_GMTYPE_HERO)
                    ArrayPushCell(lArrayGamemodeList, lGamemodeId)
            }
        }
        case ZI_GMTYPE_ARMAGEDDON:
        {
            for(new i; i < lArraySize; i++)
            {
                lGamemodeId = ArrayGetCell(arrayGamemodeId, i)

                if(lGamemodeId == modeBefore && lArraySize > 1)
                    continue

                if(ArrayGetCell(arrayGamemodeType, i) == ZI_GMTYPE_ARMAGEDDON)
                    ArrayPushCell(lArrayGamemodeList, lGamemodeId)
            }
        }
        case ZI_GMTYPE_NONE:
        {
            for(new i; i < lArraySize; i++)
            {
                lGamemodeId = ArrayGetCell(arrayGamemodeId, i)

                if(lGamemodeId == modeBefore && lArraySize > 1)
                    continue
                
                ArrayPushCell(lArrayGamemodeList, lGamemodeId)
            }
        }
    }

    new lRandomId = ArrayGetCell(lArrayGamemodeList, random(ArraySize(lArrayGamemodeList)-1))
    ArrayDestroy(lArrayGamemodeList)

    return lRandomId
}

infectPlayer(victim, attacker, zombieClass, subClass)
{
    if(!is_user_alive(victim))
        return false
    
    new lArrayId = ArrayFindValue(arrayClassZombieSubId, subClass)

    if(lArrayId == -1)
    {
        log_amx("[INFECTPLAYER] Array id was not found by subclass! (%d)", subClass)
        return false
    }

    if(gGamemodeCurrent)
    {
        cs_set_user_team(victim, CS_TEAM_T)
    }

    if(zombieClass == ZI_CLASS_NONE || subClass == ZI_CLASS_NONE)
    {
        zombieClass = ZI_ZMCLASS_NORMAL
        subClass = ZI_ZMSUBCLASS_NORMAL1
    }

    gUserClassZombie[victim] = zombieClass
    gUserClassZombieSub[victim] = subClass
    gUserClassHuman[victim] = ZI_CLASS_NONE
    gUserClassHero[victim] = ZI_CLASS_NONE

    new lHelpString[64]

    ArrayGetString(arrayClassZombieSubClaw, lArrayId, lHelpString, charsmax(lHelpString))
    cs_set_player_view_model(victim, CSW_KNIFE, lHelpString)
    cs_set_player_weap_model(victim, CSW_KNIFE, "")
    ArrayGetString(arrayClassZombieSubModel, lArrayId, lHelpString, charsmax(lHelpString))
    cs_set_player_model(victim, lHelpString)
    entity_set_int(victim, EV_INT_body, ArrayGetCell(arrayClassZombieSubBody, lArrayId))
    entity_set_float(victim, EV_FL_health, float(ArrayGetCell(arrayClassZombieSubHealth, lArrayId)))
    cs_set_player_maxspeed_auto(victim, Float:ArrayGetCell(arrayClassZombieSubSpeed, lArrayId))
    entity_set_float(victim, EV_FL_gravity, Float:ArrayGetCell(arrayClassZombieSubGravity, lArrayId))

    ExecuteForward(gForwardUserInfect, retValue, victim, attacker, zombieClass, subClass)
    return true
}

curePlayer(victim, attacker, humanClass)
{
    if(!is_user_alive(victim))
        return false
    
    new lArrayId = ArrayFindValue(arrayClassHumanId, humanClass)

    if(lArrayId == -1)
    {
        log_amx("[CUREPLAYER] Array id was not found by humanclass! (%d)", humanClass)
        return false
    }

    if(gGamemodeCurrent)
    {
        cs_set_user_team(victim, CS_TEAM_CT)
    }
    
    if(humanClass == ZI_CLASS_NONE)
        humanClass = ZI_HMCLASS_NORMAL

    gUserClassZombie[victim] = ZI_CLASS_NONE
    gUserClassZombieSub[victim] = ZI_CLASS_NONE
    gUserClassHuman[victim] = humanClass
    gUserClassHero[victim] = ZI_CLASS_NONE

    new lHelpString[64]

    ArrayGetString(arrayClassHumanModel, lArrayId, lHelpString, charsmax(lHelpString))
    cs_set_player_model(victim, lHelpString)
    entity_set_int(victim, EV_INT_body, ArrayGetCell(arrayClassHumanBody, lArrayId))

    ExecuteForward(gForwardUserCure, retValue, victim, attacker, humanClass)
    return true
}

heroisatePlayer(id, heroClass)
{
    if(!is_user_alive(id))
        return false

    cs_set_user_team(id, ArrayGetCell(arrayClassHeroTeam, ArrayFindValue(arrayClassHeroId, heroClass)))

    gUserClassZombie[id] = ZI_CLASS_NONE
    gUserClassZombieSub[id] = ZI_CLASS_NONE
    gUserClassHuman[id] = ZI_CLASS_NONE
    gUserClassHero[id] = heroClass

    ExecuteForward(gForwardUserHeroisate, retValue, id, heroClass)
    return true
}

getPlayerZombie(id, next = false)
{
    if(next)
        return gUserClassZombieNext[id]
    
    if(!is_user_alive(id))
        return false
    
    return gUserClassZombie[id]
}

getPlayerZombieSub(id, next = false)
{
    if(next)
        return gUserClassZombieSubNext[id]
    
    if(!is_user_alive(id))
        return false

    return gUserClassZombieSub[id]
}

getPlayerHuman(id, next = false)
{
    if(next)
        return gUserClassHumanNext[id]

    if(!is_user_alive(id))
        return false
    
    return gUserClassHuman[id]
}

getPlayerHero(id)
{
    if(!is_user_alive(id))
        return false
    
    return gUserClassHero[id]
}

isLastPlayer(id, CsTeams:team)
{
    new count

    if(!is_user_alive(id) || cs_get_user_team(id) != team)
        return false

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_connected(i))
            continue
        
        if(cs_get_user_team(i) == team)
            count++
    }

    if(count == 1)
        return true

    return false
}

checkLastPlayer()
{
    new countZombie, countHuman
    new idZombie, idHuman

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_alive(i))
            continue
        
        if(cs_get_user_team(i) == ZI_TEAM_ZOMBIE)
        {
            idZombie = i
            countZombie++

            if(countZombie > 1)
                break
        }
    }

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_alive(i))
            continue
        
        if(cs_get_user_team(i) == ZI_TEAM_HUMAN)
        {
            idHuman = i
            countHuman++

            if(countHuman > 1)
                break
        }
    }

    if(countHuman == 1)
        ExecuteForward(gForwardUserLast, retValue, idHuman, ZI_TEAM_HUMAN)
    
    if(countZombie == 1)
        ExecuteForward(gForwardUserLast, retValue, idZombie, ZI_TEAM_ZOMBIE)
}