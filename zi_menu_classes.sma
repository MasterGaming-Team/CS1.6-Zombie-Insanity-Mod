#include <amxmodx>
#include <amxconst>
#include <mg_core>
#include <zi_core>

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

public plugin_init()
{
    zi_core_arrayid_zombie_get(int:arrayClassZombieId, int:arrayClassZombieName, int:arrayClassZombieDesc)
    zi_core_arrayid_zombiesub_get(int:arrayClassZombieSubParent, int:arrayClassZombieSubId, int:arrayClassZombieSubName, int:arrayClassZombieSubDesc,
                    _, _, int:arrayClassZombieSubHealth, int:arrayClassZombieSubSpeed, int:arrayClassZombieSubGravity)
    zi_core_arrayid_human_get(int:arrayClassHumanId, int:arrayClassHumanName, int:arrayClassHumanDesc)
}