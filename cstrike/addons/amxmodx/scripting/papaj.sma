#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <fakemeta>
#include <cstrike>

#define PLUGIN "Papaj 21:37"
#define VERSION "1.0"
#define AUTHOR "bordeux"

#define FILTER_DURATION 60.0 // Duration in seconds
#define SOUND_FILE "papaj2137.mp3" // Sound file path
#define TASK_MAINTAIN 2137 // Task ID for maintaining filter
#define TASK_REMOVE 21370 // Task ID for removing filter
#define KNIFE_MODEL "models/papaj_gun.mdl" // Custom knife model

new bool:g_bFilterActive = false // Track if filter is currently active
new bool:g_bTriggeredToday = false // Track if auto-trigger already happened today

// Weapon storage for each player (max 32 players, max 32 weapons per player)
#define MAX_WEAPONS 32
new g_iPlayerWeapons[33][MAX_WEAPONS]
new g_iPlayerWeaponAmmo[33][MAX_WEAPONS]
new g_iPlayerWeaponCount[33]
new g_iPlayerBPAmmo[33][MAX_WEAPONS]

public plugin_precache() {
    // Precache MP3 file so clients download it from the server
    new sound_path[64]
    format(sound_path, 63, "sound/%s", SOUND_FILE)
    precache_generic(sound_path)

    // Precache custom knife model
    precache_model(KNIFE_MODEL)
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_concmd("papaj2137", "cmd_papaj", ADMIN_KICK, "- Trigger papaj effect")

    // Register events to block weapon pickup and enforce knife
    register_event("CurWeapon", "event_CurWeapon", "be")
    register_event("ResetHUD", "event_ResetHUD", "be")
    register_forward(FM_Touch, "fw_Touch")

    // Check time every 30 seconds for auto-trigger at 21:37
    set_task(30.0, "check_time", 2138, "", 0, "b")
}

public cmd_papaj(id) {
    // Trigger the papaj effect
    trigger_papaj_effect()

    return PLUGIN_HANDLED
}

public apply_yellow_filter() {
    new players[32], num
    get_players(players, num, "a") // Get all alive and connected players

    for(new i = 0; i < num; i++) {
        new player = players[i]

        // Screen fade parameters
        // ScreenFade(duration, holdtime, flags, r, g, b, alpha)
        // Duration and holdtime are in special units (1/4096 of a second)
        // 60 seconds = 60 * 4096 = 245760 units

        message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, player)
        write_short(1<<12) // Duration: 1 second fade in
        write_short(floatround(FILTER_DURATION * 4096.0)) // Hold time: 60 seconds
        write_short(0x0004) // FFADE_STAYOUT flag
        write_byte(255) // Red
        write_byte(255) // Green
        write_byte(0)   // Blue (Yellow = Red + Green)
        write_byte(100) // Alpha (transparency, 0-255, 100 = semi-transparent)
        message_end()
    }
}

public maintain_yellow_filter() {
    // Continuously reapply the filter to ensure it stays on during round changes
    if(g_bFilterActive) {
        apply_yellow_filter()
    }
}

public check_time() {
    // Get current time
    new hour, minute, second
    time(hour, minute, second)

    // Check if it's 21:37
    if(hour == 21 && minute == 37) {
        // Only trigger once per day
        if(!g_bTriggeredToday) {
            g_bTriggeredToday = true

            // Trigger the papaj effect automatically
            trigger_papaj_effect()

            // Log the automatic trigger
            log_amx("Papaj effect auto-triggered at 21:37")
        }
    } else {
        // Reset the flag after 21:37 passes
        if(hour != 21 || minute != 37) {
            g_bTriggeredToday = false
        }
    }
}

public save_user_weapons(id) {
    // Reset weapon count
    g_iPlayerWeaponCount[id] = 0

    // Get all weapons the player has
    new weapons[MAX_WEAPONS], num
    get_user_weapons(id, weapons, num)

    // Save each weapon and its ammo
    for(new i = 0; i < num; i++) {
        new weaponid = weapons[i]

        // Don't save knife
        if(weaponid == CSW_KNIFE)
            continue

        // Save weapon ID
        g_iPlayerWeapons[id][g_iPlayerWeaponCount[id]] = weaponid

        // Save clip ammo and backpack ammo
        new clip, ammo
        get_user_ammo(id, weaponid, clip, ammo)
        g_iPlayerWeaponAmmo[id][g_iPlayerWeaponCount[id]] = clip
        g_iPlayerBPAmmo[id][g_iPlayerWeaponCount[id]] = ammo

        g_iPlayerWeaponCount[id]++
    }
}

public restore_user_weapons(id) {
    // Check if player is alive
    if(!is_user_alive(id))
        return

    // Restore each saved weapon
    for(new i = 0; i < g_iPlayerWeaponCount[id]; i++) {
        new weaponid = g_iPlayerWeapons[id][i]

        // Get weapon name
        new weapon_name[32]
        get_weaponname(weaponid, weapon_name, 31)

        // Give the weapon back
        give_item(id, weapon_name)

        // Restore ammo
        cs_set_user_bpammo(id, weaponid, g_iPlayerBPAmmo[id][i])

        // Note: Clip ammo will be set automatically when weapon is given
    }

    // Reset weapon count
    g_iPlayerWeaponCount[id] = 0
}

public strip_user_weapons_give_knife(id) {
    // Strip all weapons except knife
    strip_user_weapons(id)

    // Give knife
    give_item(id, "weapon_knife")
}

public event_CurWeapon(id) {
    // Only enforce during active papaj effect
    if(!g_bFilterActive)
        return PLUGIN_CONTINUE

    new wpnid = read_data(2)

    // If player is holding anything other than knife, switch to knife
    if(wpnid != CSW_KNIFE) {
        engclient_cmd(id, "weapon_knife")
        return PLUGIN_HANDLED
    }

    // Set custom knife model
    set_pev(id, pev_viewmodel2, KNIFE_MODEL)

    return PLUGIN_CONTINUE
}

public event_ResetHUD(id) {
    // Only enforce during active papaj effect
    if(!g_bFilterActive)
        return PLUGIN_CONTINUE

    // Player just spawned, strip weapons and give knife with custom model
    set_task(0.1, "task_enforce_knife_on_spawn", id)

    return PLUGIN_CONTINUE
}

public task_enforce_knife_on_spawn(id) {
    // Check if player is still alive and effect is still active
    if(!is_user_alive(id) || !g_bFilterActive)
        return

    // Strip all weapons and give only knife
    strip_user_weapons_give_knife(id)

    // Force player to use knife
    engclient_cmd(id, "weapon_knife")

    // Apply custom knife model
    set_pev(id, pev_viewmodel2, KNIFE_MODEL)
}

public fw_Touch(entity, id) {
    // Only block during active papaj effect
    if(!g_bFilterActive)
        return FMRES_IGNORED

    // Check if a player is trying to touch a weapon
    if(!is_user_alive(id))
        return FMRES_IGNORED

    new classname[32]
    pev(entity, pev_classname, classname, 31)

    // Block touching any weapon except knife
    if(equal(classname, "weaponbox") || equal(classname, "armoury_entity") ||
       (containi(classname, "weapon_") != -1 && !equal(classname, "weapon_knife"))) {
        return FMRES_SUPERCEDE
    }

    return FMRES_IGNORED
}

public trigger_papaj_effect() {
    // Mark filter as active
    g_bFilterActive = true

    // Apply yellow filter to all players
    apply_yellow_filter()

    // Play MP3 sound and strip weapons from all players
    new players[32], num
    get_players(players, num, "a")
    for(new i = 0; i < num; i++) {
        client_cmd(players[i], "mp3 play sound/%s", SOUND_FILE)

        // Save current weapons before stripping
        save_user_weapons(players[i])

        // Strip all weapons and give only knife
        strip_user_weapons_give_knife(players[i])
    }

    // Set repeating task to maintain filter every 0.5 seconds (to survive round restarts)
    set_task(0.5, "maintain_yellow_filter", TASK_MAINTAIN, "", 0, "b")

    // Set timer to remove filter after 60 seconds
    set_task(FILTER_DURATION, "remove_yellow_filter", TASK_REMOVE)

    // Notify all players
    client_print(0, print_chat, "[Papaj] Papieski czas, kremowki w dlon!")
}

public remove_yellow_filter() {
    // Mark filter as inactive
    g_bFilterActive = false

    // Stop the repeating maintain task
    remove_task(TASK_MAINTAIN)

    new players[32], num
    get_players(players, num, "a") // Get all alive and connected players

    for(new i = 0; i < num; i++) {
        new player = players[i]

        // Clear the screen fade with FFADE_OUT flag
        message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, player)
        write_short(1<<12) // Duration: 1 second fade out
        write_short(0) // Hold time: 0
        write_short(0x0001) // FFADE_OUT flag - fade out and remove
        write_byte(0) // Red
        write_byte(0) // Green
        write_byte(0) // Blue
        write_byte(0) // Alpha
        message_end()

        // Stop the MP3 playback
        client_cmd(player, "mp3 stop")

        // Restore default knife model
        set_pev(player, pev_viewmodel2, "models/v_knife.mdl")

        // Restore saved weapons
        restore_user_weapons(player)
    }

    // Notify all players that the filter has been removed
    client_print(0, print_chat, "[Papaj] Koniec papieskiego czasu!")
}