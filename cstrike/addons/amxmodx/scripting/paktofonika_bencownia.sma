#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Paktofonika"
#define VERSION "1.0"
#define AUTHOR "Mili 1."

new enabled;
new bool:sound_played_this_round;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_TakeDamage, "player", "fw_Player_TakeDamage");

    register_event("HLTV", "event_round_start", "a", "1=0", "2=0");

    enabled = register_cvar("mp_paktofonika", "1");
}

public event_round_start()
{
    sound_played_this_round = false;
}

public fw_Player_TakeDamage(victim, inflictor, attacker, Float:damage, dmgtype)
{
    if (!get_pcvar_num(enabled))
        return HAM_IGNORED;

    if (!(dmgtype & DMG_FALL))
        return HAM_IGNORED;

    new Float:health = float(get_user_health(victim));
    new Float:newhealth = health - damage;

    if (newhealth <= 0.0)
    {
        dmg_fall_killed_player(victim, damage);
    }

    return HAM_IGNORED; // allow normal damage processing
}

public dmg_fall_killed_player(victim, Float:damage)
{
    if (sound_played_this_round)
        return;

    client_cmd(0, "spk sound/bencownia/benc_jestembogiem1.wav");
    sound_played_this_round = true;
}

public plugin_precache() 
{
    precache_sound("bencownia/benc_jestembogiem1.wav");
}
