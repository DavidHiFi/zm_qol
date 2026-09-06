// ============================================================================
//  qol_solo_ee.gsc  (TranZit)  -  SOLO EASTER EGGS, the Maxis turbine steps
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zm_transit/qol_solo_ee.gsc
//
//  Adapted from Hadi77KSA's "Plutonium T6 Any Player EE Scripts" v2.4.1
//  (tranzit_maxis_any_player_ee.gsc), on the user's explicit instruction of
//  2026-09-06: *"in all the classic maps in the pre-game lobby screen, add an
//  option to enable/disable solo easter eggs, here's the mod to add to mine"*.
//
//  WHAT IT CHANGES: the Maxis quest's TOWER step and LAMP POST step normally
//  want one turbine per player. With one player in the lobby that is still two
//  turbines in two places at once, which is why the Maxis side has never been
//  soloable in stock. This makes both steps accept a SINGLE turbine while
//  level.players.size <= any_player_ee_transit_maxis_1p (default 1).
//
//  ⭐ IT DOES NOTHING UNLESS THE LOBBY ROW SAYS SO. `solo_ee` is written by the
//  SOLO EASTER EGGS row in the pre-game lobby (ui_mp/t6/menus/
//  privategamelobby_project.lua) and defaults to 0, so a player who never
//  touches the row gets stock Black Ops II behaviour exactly.
//
//  🛑 THREE DELIBERATE DIFFERENCES FROM THE SOURCE SCRIPT, none cosmetic:
//
//    1. NO `#define`. The source uses a CHECK_OVERRIDE macro; AI_CONTEXT.md
//       golden rule 1 forbids the C preprocessor in this project's GSC, so
//       every macro is expanded by hand here. The only behaviour lost is the
//       macro's iPrintLn debug spam when one of the tuning dvars is changed
//       mid-game - the re-read itself is kept, so live console tuning still
//       works.
//
//    2. THE DVAR IS READ AFTER flag_wait( "initial_players_connected" ), not
//       at init(). Same reason zm_nuked.gsc reads nuked_all_machines late: the
//       lobby's write has certainly landed by then. 🌟 MEASURED, not assumed -
//       _zm.gsc::onallplayersready() sets initial_players_connected and only
//       then threads start_zombie_logic_in_x_sec( 3.0 ), so this gate is a
//       full three seconds AHEAD of "start_zombie_round_logic", which is what
//       every thread below waits on anyway. Nothing can be missed.
//
//    3. NO on-screen "Any Player EE Mod" banner. It is another mod's branding
//       and this mod has its own credits line. The state goes to
//       console_zm.log instead, where a boot report can quote it.
//
//  📝 is_sidequest_allowed( "zclassic" ) is stock's own gate and is kept
//  verbatim: it returns 0 on EASY difficulty and 0 whenever g_gametype is not
//  "zclassic" - which is what keeps every Green Run SURVIVAL and GRIEF
//  location (Bus Depot, Farm, Town, Diner) out of this file, since they run
//  "zstandard" / "zgrief" on the same level.script. The lobby row is filtered
//  the same way; this is the belt to its braces.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
    if ( !maps\mp\zombies\_zm_sidequests::is_sidequest_allowed( "zclassic" ) )
        return;

    thread qol_solo_ee_gate();
}

qol_solo_ee_gate()
{
    flag_wait( "initial_players_connected" );

    if ( getdvarintdefault( "solo_ee", 0 ) != 1 )
    {
        println( "[zm_qol] SOLO EASTER EGGS: off (TranZit)" );
        return;
    }

    println( "[zm_qol] SOLO EASTER EGGS: on (TranZit - Maxis tower + lamp post steps)" );
    thread qol_sidequest_main();
}

qol_sidequest_main()
{
    flag_wait( "start_zombie_round_logic" );
    waittillframeend;

    if ( level.richcompleted && level.maxcompleted )
        return;

    for (;;)
    {
        thread qol_maxis_sidequest();
        flag_wait( "power_on" );
        flag_waitopen( "power_on" );
    }
}

qol_maxis_sidequest()
{
    if ( flag( "power_on" ) || level.maxcompleted )
        return;

    thread qol_watch_turbine_use();
    thread qol_maxis_sidequest_c();
}

//  THE TOWER STEP. Stock counts one "turbine_deployed" notify per turbine under
//  the tower. Re-firing the notify twice a frame later makes one turbine count
//  as the whole team's worth.
qol_watch_turbine_use()
{
    level endon( "power_on" );
    level endon( "transit_sidequest_achieved" );
    n_solo_max = 1;

    for (;;)
    {
        level waittill( "turbine_deployed" );
        n_solo_max = getdvarintdefault( "any_player_ee_transit_maxis_1p", 1 );

        if ( level.players.size <= n_solo_max )
        {
            waittillframeend;
            waittillframeend;
            level notify( "turbine_deployed" );
        }
    }
}

//  THE LAMP POST STEP. level.sq_progress["maxis"]["C_turbine_1"] and _2 are the
//  two lamp posts; solo can only ever power one, so whichever is set is copied
//  onto the other. The else branch is stock's own book-keeping, restored when
//  the player count rises above the solo threshold mid-match.
qol_maxis_sidequest_c()
{
    flag_wait( "power_on" );
    flag_waitopen( "power_on" );
    level endon( "power_on" );
    level endon( "transit_sidequest_achieved" );

    for (;;)
    {
        level maps\mp\_utility::waittill_either( "turbine_deployed", "connected" );
        waittillframeend;

        if ( level.players.size <= getdvarintdefault( "any_player_ee_transit_maxis_1p", 1 ) )
        {
            if ( isdefined( level.sq_progress["maxis"]["C_turbine_1"] ) )
            {
                if ( !isdefined( level.sq_progress["maxis"]["C_turbine_2"] ) )
                    level.sq_progress["maxis"]["C_turbine_2"] = level.sq_progress["maxis"]["C_turbine_1"];
            }
            else if ( isdefined( level.sq_progress["maxis"]["C_turbine_2"] ) )
                level.sq_progress["maxis"]["C_turbine_1"] = level.sq_progress["maxis"]["C_turbine_2"];

            waittillframeend;
            waittillframeend;
        }
        else
        {
            if ( isdefined( level.sq_progress["maxis"]["C_turbine_1"] ) && !isdefined( level.sq_progress["maxis"]["C_screecher_1"] ) )
                level.sq_progress["maxis"]["C_turbine_1"] = undefined;
            else if ( isdefined( level.sq_progress["maxis"]["C_turbine_2"] ) && !isdefined( level.sq_progress["maxis"]["C_screecher_2"] ) )
                level.sq_progress["maxis"]["C_turbine_2"] = undefined;
        }
    }
}
