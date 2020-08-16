#include <amxmodx>
#include <amxmisc>
#include <zi_core>

#define PLUGIN "[MG][ZI] Gamemode Armageddon"
#define VERSION "1.0.0"
#define AUTHOR "Vieni"

new const gGamemodeId = ZI_GAMEMODE_ARMAGEDDON
new const gGamemodeName[] = "ZI_NGAMEMODE_ARMAGEDDON"

new gMaxPlayers

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    gMaxPlayers = get_maxplayers()

    zi_core_gamemode_reg(gGamemodeId, gGamemodeName, ZI_GMTYPE_ARMAGEDDON, true, true, true, false)
}

public zi_fw_gamemode_start(gamemodeId)
{
    if(gamemodeId != gGamemodeId)
        return

    infectRandomPlayer()
}

infectRandomPlayer()
{
    new Array:lArrayPlayerList

    lArrayPlayerList = ArrayCreate(1)

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_alive(i))
            continue
        
        ArrayPushCell(lArrayPlayerList, i)
    }

    new lArraySize = ArraySize(lArrayPlayerList)

    if(!lArraySize)
        return 0
    
    new lRandomPlayer = ArrayGetCell(lArrayPlayerList, random_num(0, lArraySize-1))

    ArrayDestroy(lArrayPlayerList)

    return lRandomPlayer
}