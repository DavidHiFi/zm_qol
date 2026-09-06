#include clientscripts\mp\_utility;
#include clientscripts\mp\zombies\_zm_utility;
#include clientscripts\mp\zombies\_zm_weapons;
#include clientscripts\mp\zm_tomb;
#include clientscripts\mp\zombies\_zm;
#include clientscripts\mp\zm_tomb_classic;

main()
{
    replaceFunc(clientscripts\mp\zm_tomb::include_weapons, ::include_weapons);

    // --- Origins survival, The Crazy Place: client half. The server half is
    //     scripts\zm\replaced\zm_tomb_gamemodes.gsc, hooked from
    //     scripts\zm\zm_tomb\zm_tomb.gsc::main(). Ship the two together. ---
    replaceFunc(clientscripts\mp\zm_tomb::init_gamemodes, ::init_gamemodes);
}

// ============================================================================
//  init_gamemodes  (CLIENT)
//
//  Same defect as zm_prison\zm_prison.csc - see the long comment there for the
//  mechanism and the _zm.csc line numbers.
//
//  Origins is worse than Mob of the Dead: stock
//  clientscripts\mp\zm_tomb::init_gamemodes registers ONLY zclassic, while
//  scripts\zm\replaced\zm_tomb_gamemodes.gsc adds zstandard AND zgrief on the
//  server (The Crazy Place, v2.14.0). With the client registering neither, its
//  start_zombie_gametype() bails, the loading state is never released, and the
//  map hangs on the loading screen instead of starting.
//
//  Both new modes point crazy_place at zm_tomb_classic's client location
//  functions. That is the same technique already shipping on Die Rise and
//  Buried, and Origins has exactly one client location script, so it is the
//  only correct target. It also keeps the clientfield sets symmetrical: the
//  client only registers a location's buildables when a location script
//  actually runs (_zm_buildables.csc registers on the FIRST buildable added),
//  which is what produced "Clientfield buildable in set [toplayer] is not
//  registered on the client" on Die Rise before the same fix.
//
//  🛑 NOT verified in game yet - Origins survival has never booted.
// ============================================================================
init_gamemodes()
{
    add_map_gamemode( "zclassic", undefined, undefined );
    add_map_gamemode( "zstandard", undefined, undefined );
    add_map_gamemode( "zgrief", undefined, undefined );

    add_map_location_gamemode( "zclassic", "tomb", clientscripts\mp\zm_tomb_classic::precache, clientscripts\mp\zm_tomb_classic::premain, clientscripts\mp\zm_tomb_classic::main );

    add_map_location_gamemode( "zstandard", "crazy_place", clientscripts\mp\zm_tomb_classic::precache, clientscripts\mp\zm_tomb_classic::premain, clientscripts\mp\zm_tomb_classic::main );
    add_map_location_gamemode( "zgrief", "crazy_place", clientscripts\mp\zm_tomb_classic::precache, clientscripts\mp\zm_tomb_classic::premain, clientscripts\mp\zm_tomb_classic::main );
}

include_weapons()
{
    include_weapon( "hamr_zm" );
    include_weapon( "hamr_upgraded_zm", 0 );
    include_weapon( "mg08_zm" );
    include_weapon( "mg08_upgraded_zm", 0 );
    include_weapon( "type95_zm", 0 ); //
    include_weapon( "type95_upgraded_zm", 0 );
    include_weapon( "galil_zm" );
    include_weapon( "galil_upgraded_zm", 0 );
    include_weapon( "fnfal_zm", 0 ); //
    include_weapon( "fnfal_upgraded_zm", 0 );
    include_weapon( "m14_zm", 0 );
    include_weapon( "m14_upgraded_zm", 0 );
    include_weapon( "mp44_zm", 0 );
    include_weapon( "mp44_upgraded_zm", 0 );
    include_weapon( "scar_zm" );
    include_weapon( "scar_upgraded_zm", 0 );
    include_weapon( "870mcs_zm", 0 );
    include_weapon( "870mcs_upgraded_zm", 0 );
    include_weapon( "ksg_zm", 0 ); //
    include_weapon( "ksg_upgraded_zm", 0 );
    include_weapon( "srm1216_zm", 0  ); //
    include_weapon( "srm1216_upgraded_zm", 0 );
    include_weapon( "ak74u_zm", 0 );
    include_weapon( "ak74u_upgraded_zm", 0 );
    include_weapon( "ak74u_extclip_zm", 0 ); //
    include_weapon( "ak74u_extclip_upgraded_zm", 0 );
    include_weapon( "pdw57_zm", 0 ); //
    include_weapon( "pdw57_upgraded_zm", 0 );
    include_weapon( "thompson_zm" );
    include_weapon( "thompson_upgraded_zm", 0 );
    include_weapon( "qcw05_zm", 0 ); //
    include_weapon( "qcw05_upgraded_zm", 0 );
    include_weapon( "mp40_zm", 0 );
    include_weapon( "mp40_upgraded_zm", 0 );
    include_weapon( "mp40_stalker_zm" );
    include_weapon( "mp40_stalker_upgraded_zm", 0 );
    include_weapon( "evoskorpion_zm" );
    include_weapon( "evoskorpion_upgraded_zm", 0 );
    include_weapon( "ballista_zm", 0 );
    include_weapon( "ballista_upgraded_zm", 0 );
    include_weapon( "dsr50_zm", 0 ); //
    include_weapon( "dsr50_upgraded_zm", 0 );
    include_weapon( "beretta93r_zm", 0 );
    include_weapon( "beretta93r_upgraded_zm", 0 );
    include_weapon( "beretta93r_extclip_zm", 0 ); //
    include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
    include_weapon( "kard_zm", 0 ); //
    include_weapon( "kard_upgraded_zm", 0 );
    include_weapon( "fiveseven_zm", 0 );
    include_weapon( "fiveseven_upgraded_zm", 0 );
    include_weapon( "python_zm", 0 ); //
    include_weapon( "python_upgraded_zm", 0 );
    include_weapon( "c96_zm", 0 );
    include_weapon( "c96_upgraded_zm", 0 );
    include_weapon( "fivesevendw_zm" );
    include_weapon( "fivesevendw_upgraded_zm", 0 );
    include_weapon( "m32_zm" );
    include_weapon( "m32_upgraded_zm", 0 );
    include_weapon( "beacon_zm", 0 );
    include_weapon( "tomb_shield_zm", 0 );
    include_weapon( "claymore_zm", 0 );
    include_weapon( "cymbal_monkey_zm" );
    include_weapon( "frag_grenade_zm", 0 );
    include_weapon( "knife_zm", 0 );
    include_weapon( "ray_gun_zm" );
    include_weapon( "ray_gun_upgraded_zm", 0 );
    include_weapon( "sticky_grenade_zm", 0 );
    include_weapon( "staff_air_zm", 0 );
    include_weapon( "staff_air_upgraded_zm", 0 );
    include_weapon( "staff_fire_zm", 0 );
    include_weapon( "staff_fire_upgraded_zm", 0 );
    include_weapon( "staff_lightning_zm", 0 );
    include_weapon( "staff_lightning_upgraded_zm", 0 );
    include_weapon( "staff_water_zm", 0 );
    include_weapon( "staff_water_zm_cheap", 0 );
    include_weapon( "staff_water_upgraded_zm", 0 );
    include_weapon( "staff_revive_zm", 0 );
    // ========================================================================
    //  🛑 v2.14.2 - EXACT TWIN OF zm_tomb.gsc::added_weapons()'s OWN SKIP.
    //  Read the long banner above that function for why the Crazy Place cannot
    //  afford these seven pairs (its four perk machines cost ten precacheitem
    //  calls stock's own _zm_perks::init() skips on every other Origins
    //  survival location, and v2.14.0 crashed at load because of it).
    //
    //  🛑 THIS HALF IS NOT BOOKKEEPING. include_weapon() here ends in
    //  addzombieboxweapon( weapon, getweaponmodel( weapon ), ... ) - a model
    //  lookup on a weapon the server never precached is the as50_zm client
    //  crash documented in zm_expanded.csc::zmqol_mp_weapons_init(). If the two
    //  lists ever disagree the map dies on the CLIENT instead of the server.
    //
    //  Same dvar test as the server's zmqol_loc_spawns_perk_machines(), and the
    //  same one zmqol_add_crazy_place_wallbuys() already uses client-side.
    //  📝 knife_ballistic_* is not in this list and never was - it is not a box
    //  weapon - so the server keeping it needs no twin here.
    // ========================================================================
    // Added weapons
    include_weapon( "uzi_zm" );
    include_weapon( "uzi_upgraded_zm", 0 );
    include_weapon( "ak47_zm" );
    include_weapon( "ak47_upgraded_zm", 0 );
    include_weapon( "minigun_alcatraz_zm" );
    include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
    include_weapon( "hk416_zm" );
    include_weapon( "hk416_upgraded_zm", 0 );
    include_weapon( "rnma_zm" );
    include_weapon( "rnma_upgraded_zm", 0 );
    include_weapon( "an94_zm" ); 
    include_weapon( "an94_upgraded_zm", 0 );
    include_weapon( "lsat_zm" );
    include_weapon( "lsat_upgraded_zm", 0 );
    include_weapon( "svu_zm" );
    include_weapon( "svu_upgraded_zm", 0 );
    // Tranzit weapons
    include_weapon( "xm8_zm" );
    include_weapon( "xm8_upgraded_zm", 0 );
    include_weapon( "rpd_zm" );
    include_weapon( "rpd_upgraded_zm", 0 );
    //  🛑 THE GATE - twin of zm_tomb.gsc::added_weapons()'s. Everything above is
    //  precached by the root script on every map regardless, so only the pairs
    //  below buy the Crazy Place a slot by being held back.
    if ( getdvar( "ui_zm_mapstartlocation" ) != "crazy_place" )
    {
    include_weapon( "saritchqol_zm" );
    include_weapon( "saritchqol_upgraded_zm", 0 );
    include_weapon( "barretm82qol_zm" );
    include_weapon( "barretm82qol_upgraded_zm", 0);
    include_weapon( "mp5kqol_zm" );
    include_weapon( "mp5kqol_upgraded_zm", 0);
    include_weapon( "tar21qol_zm" );
    include_weapon( "tar21qol_upgraded_zm", 0);
    include_weapon( "saiga12qol_zm" );
    include_weapon( "saiga12qol_upgraded_zm", 0);
    include_weapon( "judgeqol_zm" );
    include_weapon( "judgeqol_upgraded_zm", 0);
    include_weapon( "usrpg_zm" );
    include_weapon( "usrpg_upgraded_zm", 0);
    }
    else
        println( "[zm_qol] CLIENT crazy place: added weapons SKIPPED - 7 pair(s), matching the server" );

    //  🛑 OUTSIDE THE SKIP ON PURPOSE - twin of the same two pairs in
    //  zm_tomb.gsc::added_weapons(). The root script precaches and registers
    //  Origins' private M16 and Olympia on every location, so the client has to
    //  include them on every location too or the box cannot draw them. Read the
    //  banner beside them on the server for the full reason.
    include_weapon( "m16qol_zm" );
    include_weapon( "m16qol_upgraded_zm", 0 );
    include_weapon( "rottweil72qol_zm" );
    include_weapon( "rottweil72qol_upgraded_zm", 0 );
    include_weapon( "m1911_zm" );
    include_weapon( "m1911_upgraded_zm", 0);

    // ========================================================================
    //  v2.9.1 - THE THREE ORIGINS COPIES THAT ARE REGISTERED FROM A ROOT
    //  SCRIPT, so their client half cannot live where the other six do.
    //
    //  quality_of_life.gsc registers the XPR-50 through zmqol_add_mp_weapon()
    //  and the M16 / Olympia through zmqol_wallbuy_box_add(), both of which run
    //  on every map and swap in the private Origins copy via
    //  zmqol_tomb_weapon(). Their client twins in zm_expanded.csc cannot make
    //  that swap: level.script is never used by any stock .csc in the 618-file
    //  client dump, so there is no verified way to test the map client-side.
    //  This file only ever loads on Origins, so the includes simply go here.
    //
    //  📝 The twins in zm_expanded.csc still include the STOCK m16_zm /
    //  rottweil72_zm / as50_zm here as well. That is harmless: the server never
    //  registers those three on Origins, so they can never be a box result, and
    //  they name the SAME view models as the copies - so even the box's spin
    //  visual is identical.
    // ========================================================================
    //  🛑 ONLY the XPR-50 here. The M16 and the Olympia are already included
    //  above - this map's own list carries them - and include_weapon() twice
    //  for one name would be a duplicate, not a second entry.
    include_weapon( "as50qol_zm" );
    include_weapon( "as50qol_upgraded_zm", 0 );


    if ( is_true( level.raygun2_included ) && !isdemoplaying() )
    {
        include_weapon( "raygun_mark2_zm", hasdlcavailable( "dlc3" ) );
        include_weapon( "raygun_mark2_upgraded_zm", 0 );
    }
}