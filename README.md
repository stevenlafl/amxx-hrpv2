# HarbuRP v2 (AKA HybridRP)

This amxmodx mod was created by Eric Andrews <Harbu> and Steven Linn <StevenlAFl> for the Half-Life mod The Specialists. It's purpose is to facilitate roleplay.

## Installation
- Download and install Metamod
- Download and install AMXModx and addon:
  - The Specialists

## Chat commmands
- `/cuff`
- `/rope`
- `/tazer`
- `/togglecam`
- `/help`
- `/laws`
- `/commands`
- `/resign`
- `/jobs`
- `/guns`
- `/stuck`

## Commands
### For Users

- `amx_dropitem`
- `amx_serverstats`

### For admins

Item
- `amx_list_item` - list all items
- `amx_info_item` `<id>`
- `amx_createitem` `<id>` `<title>` `<desc>` `<show_int>` `<give>` `<drop>` `[func]` `[parameter]`
- `amx_destroyitem` `<id>`
- `amx_give_item` `<name>` `<id>` `[value]`
- `amx_take_item` `<name>` `<id>` `[value]`
- `amx_take_all` `<name>` `<id>`
- `amx_reset_item` `<name>`

NPC
- `amx_create_npc`

Timer
- `amx_advance_hour` - advance the clock by one hour
- `amx_advance_day` - advance the date by one day
- `amx_advance_month` - advance the date by one month
- `amx_advance_year` - advance the date by one month
- `amx_settime` `<minute>` `<hour>` `<day>` `<month>` `<year>`

Weapons
- `amx_weaponspawn` `<weaponid>` `<ammo>` `<spawnflags>` `<permanent 1/0>` `<infront 1/0>`
- `amx_removespawn` `[classname]`

Base
- `amx_invis` `<name>` `<0/1>`
- `amx_forceuse` `<entid>`
- `amx_ssay` `<message>`
- `amx_alldropweapons`
- `amx_giveweapon` `<name>` `<weaponid>` `<clips>` `<flags>`

Employment
- `amx_employ` `<name>` `<id>`
- `amx_setjob` `<name>` `<id>`
- `amx_setflag` `<name>` `<right>`
- `amx_createjob` `<id>` `<org>` `<title>` `<salary>` `<flag>`
- `amx_destroyjob` `<id>`
- `amx_list_job` - list of all the servers jobs
- `amx_ban_job` `<name>` `<id>` `<1/0>`

Extra Functions
- `amx_create_info` `<text>`
- `amx_create_camera` `<name>`
- `amx_pkaccess` `<name>` `<access 1/0>`
- `amx_remove` `<1/0>`
- `amx_god` `<1/0>`
- `amx_nulltarget` `<1/0>`

Property
- `amx_list_property` - list all properties
- `amx_create_property` `<title>` `<price>` `[lock 1|0]` `[jobidkey]`
- `amx_destroy_property` `[ent]`
- `amx_attach_property` `[ent]` `[ent target]`
- `amx_lock` `[ent]`
- `amx_sell` `<amount|0>` `[ent]`
- `amx_owner` `<text>` `[steamid]` `[ent]`
- `amx_profit` `[take? 1/0]`
- `amx_take_deed` `<name or steamid>` `[ent]`
- `amx_give_deed` `<name or steamid>` `[ent]`
- `amx_give_key_normal` `<name or steamid>` `[ent]`
- `amx_give_key_master` `<name or steamid>` `[ent]`
- `amx_take_key_normal` `<name or steamid>` `[ent]`
- `amx_take_key_master` `<name or steamid>` `[ent]`

Money
- `amx_createmoney` `<name>` `<amount>` `[wallet]`
- `amx_destroymoney` `<name>` `<amount>` `[wallet]`
- `amx_setmoney` `<name>` `<amount>` `[wallet]`
- `amx_create_atm` `[x]` `[y]` `[z]`
- `amx_destroy_atm` `[id]`
- `amx_list_atm` - list atm's coordinates
