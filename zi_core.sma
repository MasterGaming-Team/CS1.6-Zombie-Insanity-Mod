#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <mg_core_const>
#include <zi_core_const>

#define PLUGIN "[MG][ZI] Core plugin"
#define VERSION "1.0"
#define AUTHOR "Vieni"

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
new Array:arrayClassZombieName
new Array:arrayClassZombieDesc
new Array:arrayClassZombieModel

new Array:arrayClassZombieSubParent
new Array:arrayClassZombieSubId
new Array:arrayClassZombieSubName
new Array:arrayClassZombieSubDesc
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

new bool:gAllowLaser, bool:gAllowShield, bool:gAllowInfect, bool:gAllowRespawn

new gUserClassZombieNext[33], gUserClassZombieSubNext[33], gUserClassHumanNext[33]
new gUserClassHero[33], gUserClassZombie[33], gUserClassZombieSub[33], gUserClassHuman[33]

new retValue

new gForwardUserInfect, gForwardUserCure, gForwardUserHeroisate

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    gForwardUserInfect = CreateMultiForward("zi_fw_client_infect", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
    gForwardUserCure = CreateMultiForward("zi_fw_client_cure", ET_CONTINUE, FP_CELL, FP_CELL)
    gForwardUserHeroisate = CreateMultiForward("zi_fw_client_heroisate", ET_CONTINUE, FP_CELL, FP_CELL)
}

public plugin_natives()
{
    arrayGamemodeId = ArrayCreate(1)
    arrayGamemodeName = ArrayCreate(64)
    arrayGamemodeType = ArrayCreate(1)
    arrayGamemodeAllowLaser = ArrayCreate(1)
    arrayGamemodeAllowShield = ArrayCreate(1)
    arrayGamemodeAllowInfect = ArrayCreate(1)
    arrayGamemodeAllowRespawn = ArrayCreate(1)

    arrayClassZombieId = ArrayCreate(1)
    arrayClassZombieName = ArrayCreate(64)
    arrayClassZombieDesc = ArrayCreate(64)
    arrayClassZombieModel = ArrayCreate(64)

    arrayClassZombieSubParent = ArrayCreate(1)
    arrayClassZombieSubId = ArrayCreate(1)
    arrayClassZombieSubName = ArrayCreate(64)
    arrayClassZombieSubDesc = ArrayCreate(64)
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

    register_native("zi_core_arrayid_gamemode_get", "native_core_arrayid_gamemode_get")
    register_native("zi_core_arrayid_zombie_get", "native_core_arrayid_zombie_get")
    register_native("zi_core_arrayid_zombiesub_get", "native_core_arrayid_zombiesub_get")
    register_native("zi_core_arrayid_human_get", "native_core_arrayid_human_get")
    register_native("zi_core_arrayid_hero_get", "native_core_arrayid_hero_get")
    
    register_native("zi_core_allow_laser", "native_core_allow_laser")
    register_native("zi_core_allow_shield", "native_core_allow_shield")
    register_native("zi_core_allow_infect", "native_core_allow_infect")
    register_native("zi_core_allow_respawn", "native_core_allow_respawn")

    register_native("zi_core_gamemode_reg", "native_core_gamemode_reg")

    register_native("zi_core_class_zombie_reg", "native_core_class_zombie_reg")
    register_native("zi_core_class_zombiesub_reg", "native_core_class_zombiesub_reg")
    register_native("zi_core_class_human_reg", "native_core_class_human_reg")
    register_native("zi_core_class_hero_reg", "native_core_class_hero_reg")

    register_native("zi_core_class_zombie_arrayslot_get", "native_core_class_zombie_arrayslot_get")
    register_native("zi_core_class_zombiesub_arrayslot_get", "native_core_class_zombiesub_arrayslot_get")
    register_native("zi_core_class_human_arrayslot_get", "native_core_class_human_arrayslot_get")
    register_native("zi_core_class_hero_arrayslot_get", "native_core_class_hero_arrayslot_get")

    register_native("zi_core_client_zombie_get", "native_core_client_zombie_get")
    register_native("zi_core_client_zombiesub_get", "native_core_client_zombiesub_get")
    register_native("zi_core_client_human_get", "native_core_client_human_get")
    register_native("zi_core_client_hero_get", "native_core_client_hero_get")

    register_native("zi_core_client_zombie_set", "native_core_client_zombie_set")
    register_native("zi_core_client_human_set", "native_core_client_human_set")

    register_native("zi_core_client_infect", "native_core_client_infect")
    register_native("zi_core_client_cure", "native_core_client_cure")
    register_native("zi_core_client_heroisate", "native_core_client_heroisate")
}

public native_core_arrayid_gamemode_get(plugin_id, param_num)
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

public native_core_arrayid_zombie_get(plugin_id, param_num)
{
    if(get_param(1) != -1)
        set_param_byref(1, int:arrayClassZombieId)
    
    if(get_param(2) != -1)
        set_param_byref(2, int:arrayClassZombieName)
    
    if(get_param(3) != -1)
        set_param_byref(3, int:arrayClassZombieDesc)
    
    if(get_param(4) != -1)
        set_param_byref(4, int:arrayClassZombieModel)
}

public native_core_arrayid_zombiesub_get(plugin_id, param_num)
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
        set_param_byref(5, int:arrayClassZombieSubModel)

    if(get_param(6) != -1)
        set_param_byref(6, int:arrayClassZombieSubBody)

    if(get_param(7) != -1)
        set_param_byref(7, int:arrayClassZombieSubHealth)

    if(get_param(8) != -1)
        set_param_byref(8, int:arrayClassZombieSubSpeed)
    
    if(get_param(9) != -1)
        set_param_byref(9, int:arrayClassZombieSubGravity)
}

public native_core_arrayid_human_get(plugin_id, param_num)
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

public native_core_arrayid_hero_get(plugin_id, param_num)
{
    if(get_param(1) != -1)
        set_param_byref(1, int:arrayClassHeroId)
    
    if(get_param(2) != -1)
        set_param_byref(2, int:arrayClassHeroName)
    
    if(get_param(3) != -1)
        set_param_byref(3, int:arrayClassHeroTeam)
}

public native_core_allow_laser(plugin_id, param_num)
{
    return gAllowLaser
}

public native_core_allow_shield(plugin_id, param_num)
{
    return gAllowShield
}

public native_core_allow_infect(plugin_id, param_num)
{
    return gAllowInfect
}

public native_core_allow_respawn(plugin_id, param_num)
{
    return gAllowRespawn
}

public native_core_gamemode_reg(plugin_id, param_num)
{
    new lGamemodeId = get_param(1)

    if(ArrayFindValue(arrayGamemodeId, lGamemodeId) != -1)
    {
        log_amx("[GAMEMODEREG] Gamemode's already registered! (%d)", lGamemodeId)
        return ZI_GMID_NONE
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

public native_core_class_zombie_reg(plugin_id, param_num)
{
    new lClassId = get_param(1)

    if(ArrayFindValue(arrayClassZombieId, lClassId) != -1)
    {
        log_amx("[CLASSZOMBIEREG] Class is already registered! (%d)", lClassId)
        return ZI_CLASS_NONE
    }

    new lClassName[64], lClassDesc[64], lClassModel[64]

    get_string(2, lClassName, charsmax(lClassName))
    get_string(3, lClassDesc, charsmax(lClassDesc))
    get_string(4, lClassModel, charsmax(lClassModel))

    ArrayPushCell(arrayClassZombieId, lClassId)
    ArrayPushString(arrayClassZombieName, lClassName)
    ArrayPushString(arrayClassZombieDesc, lClassDesc)
    ArrayPushString(arrayClassZombieModel, lClassModel)

    return lClassId
}

public native_core_class_zombiesub_reg(plugin_id, param_num)
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

    new lClassName[64], lClassDesc[64], lClassModel[64], lClassBody, lClassHealth, Float:lClassSpeed, Float:lClassGravity

    get_string(3, lClassName, charsmax(lClassName))
    get_string(4, lClassDesc, charsmax(lClassDesc))
    get_string(5, lClassModel, charsmax(lClassModel))

    lClassBody = get_param(6)
    lClassHealth = get_param(7)
    lClassSpeed = get_param_f(8)
    lClassGravity = get_param_f(9)

    if(!lClassModel[0])
        ArrayGetString(arrayClassZombieModel, ArrayFindValue(arrayClassZombieId, lParentClassId), lClassName, charsmax(lClassName))

    ArrayPushCell(arrayClassZombieSubParent, lParentClassId)
    ArrayPushCell(arrayClassZombieId, lClassId)
    ArrayPushString(arrayClassZombieName, lClassName)
    ArrayPushString(arrayClassZombieDesc, lClassDesc)
    ArrayPushString(arrayClassZombieModel, lClassModel)
    ArrayPushCell(arrayClassZombieSubBody, lClassBody)
    ArrayPushCell(arrayClassZombieSubHealth, lClassHealth)
    ArrayPushCell(arrayClassZombieSubSpeed, lClassSpeed)
    ArrayPushCell(arrayClassZombieSubGravity, lClassGravity)

    return lClassId
}

public native_core_class_human_reg(plugin_id, param_num)
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

public native_core_class_hero_reg(plugin_id, param_num)
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

public native_core_class_zombie_arrayslot_get(plugin_id, param_num)
{
    new lClassId = get_param(1)
    new lArrayId = ArrayFindValue(arrayClassZombieId, lClassId)

    if(lArrayId == -1)
        log_amx("[CLASSZOMBIEARRAYSLOTGET] Class is not found! (%d)", lClassId)

    return lArrayId
}

public native_core_class_zombiesub_arrayslot_get(plugin_id, param_num)
{
    new lClassId = get_param(1)
    new lArrayId = ArrayFindValue(arrayClassZombieSubId, lClassId)

    if(lArrayId == -1)
        log_amx("[CLASSZOMBIESUBARRAYSLOTGET] Class is not found! (%d)", lClassId)

    return lArrayId
}

public native_core_class_human_arrayslot_get(plugin_id, param_num)
{
    new lClassId = get_param(1)
    new lArrayId = ArrayFindValue(arrayClassHumanId, lClassId)

    if(lArrayId == -1)
        log_amx("[CLASSHUMANARRAYSLOTGET] Class is not found! (%d)", lClassId)

    return lArrayId
}

public native_core_class_hero_arrayslot_get(plugin_id, param_num)
{
    new lClassId = get_param(1)
    new lArrayId = ArrayFindValue(arrayClassHeroId, lClassId)

    if(lArrayId == -1)
        log_amx("[CLASSHEROARRAYSLOTGET] Class is not found! (%d)", lClassId)

    return lArrayId
}

public native_core_client_zombie_get(plugin_id, param_num)
{
    static id, lNext
    id = get_param(1)
    lNext = get_param(2)

    return getPlayerZombie(id, lNext)
}

public native_core_client_zombiesub_get(plugin_id, param_num)
{
    static id, lNext
    id = get_param(1)
    lNext = get_param(2)

    return getPlayerZombieSub(id, lNext)
}

public native_core_client_human_get(plugin_id, param_num)
{
    static id, lNext
    id = get_param(1)
    lNext = get_param(2)

    return getPlayerHuman(id, lNext)
}

public native_core_client_hero_get(plugin_id, param_num)
{
    static id
    id = get_param(1)

    return getPlayerHero(id)
}

public native_core_client_zombie_set(plugin_id, param_num)
{
    static id, lClassId, lClassSubId, lCurrent

    id = get_param(1)
    lClassId = get_param(2)
    lClassSubId = get_param(3)
    lCurrent = get_param(4)

    if(!lCurrent)
    {
        gUserClassZombieNext[id] = lClassId
        gUserClassZombieSubNext[id] = lClassSubId
        return true
    }

    if(lClassId == ZI_CLASS_NONE)
    {
        lClassId = gUserClassZombieNext[id]
        lClassSubId = gUserClassZombieSubNext[id]
    }

    return infectPlayer(id, id, lClassId, lClassSubId)
}

public native_core_client_human_set(plugin_id, param_num)
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

public native_core_client_infect(plugin_id, param_num)
{
    static victim, attacker
    victim = get_param(1)
    attacker = get_param(2)

    if(!attacker)
        attacker = victim

    return infectPlayer(victim, attacker, gUserClassZombieNext[victim], gUserClassZombieSubNext[victim])
}

public native_core_client_cure(plugin_id, param_num)
{
    static victim, attacker
    victim = get_param(1)
    attacker = get_param(2)

    if(!attacker)
        attacker = victim
    
    return curePlayer(victim, attacker, gUserClassHumanNext[victim])
}

public native_core_client_heroisate(plugin_id, param_num)
{
    static id, lClassId
    id = get_param(1)
    lClassId = get_param(2)

    return heroisatePlayer(id, lClassId)
}

infectPlayer(victim, attacker, zombieClass, subClass)
{
    if(!is_user_alive(victim))
        return false

    gUserClassZombie[victim] = zombieClass
    gUserClassZombieSub[victim] = subClass
    gUserClassHuman[victim] = ZI_CLASS_NONE
    gUserClassHero[victim] = ZI_CLASS_NONE

    ExecuteForward(gForwardUserInfect, retValue, victim, attacker, zombieClass, subClass)
    return true
}

curePlayer(victim, attacker, humanClass)
{
    if(!is_user_alive(victim))
        return false
    
    gUserClassZombie[victim] = ZI_CLASS_NONE
    gUserClassZombieSub[victim] = ZI_CLASS_NONE
    gUserClassHuman[victim] = humanClass
    gUserClassHero[victim] = ZI_CLASS_NONE

    ExecuteForward(gForwardUserCure, retValue, victim, attacker, humanClass)
    return true
}

heroisatePlayer(id, heroClass)
{
    if(!is_user_alive(id))
        return false
    
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