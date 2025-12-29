#include <amxmodx>

#define ADMIN_FLAG ADMIN_KICK   // zmień jeśli chcesz inny level

new const sounds[][] = {
    "wilkunamikrofonie/01_9v_TOJESTTO.wav",
    "wilkunamikrofonie/02_9v_W_Glowie_Sie_Nie_Miesci.wav",
    "wilkunamikrofonie/03_9v_Jebac_leszczy.wav",
    "wilkunamikrofonie/04_9v_Z_lamusami_sie_nie2.wav",
    "wilkunamikrofonie/05_9v_Nie_ma_czasu.wav",
    "wilkunamikrofonie/06_9v_I_tak_wszystkich.wav",
    "wilkunamikrofonie/07_9v_Mam_sie_strescic.wav",
    "wilkunamikrofonie/08_9v_Prosto_z_ulicy.wav",
    "wilkunamikrofonie/09_9v_Ja_i_moje_ziomki.wav",
    "wilkunamikrofonie/10_9v_Jestem_pio_to.wav",
    "wilkunamikrofonie/11_9v_Policyjne_scierrwo.wav",
    "wilkunamikrofonie/12_9v_Twarda_bania.wav",
    "wilkunamikrofonie/13_9v_Uwalniam_instynkt.wav",
    "wilkunamikrofonie/14_9v_Czekam_na_waitr.wav",
    "wilkunamikrofonie/15_9v_To_jest_to_dzieciak.wav"
};

new const names[][] = {
    "W01 TO JEST TO",
    "W02 W glowie sie nie miesci",
    "W03 Jebac leszczy",
    "W04 Z lamusami sie nie",
    "W05 Nie ma czasu",
    "W06 I tak wszystkich",
    "W07 Mam sie strescic",
    "W08 Prosto z ulicy",
    "W09 Ja i moje ziomki",
    "W10 Jestem po to",
    "W11 Policyjne scierwo",
    "W12 Twarda bania",
    "W13 Uwalniam instynkt",
    "W14 Czekam na wiatr",
    "W15 To jest to dzieciak"
};

new const chat_texts[][] = {
    "Wilk na mikrofonie - w glowie sie nie miesci, jebac leszczy, z lamusami sie nie piescic, nie ma czasu",
    "W glowie sie nie miesci",
    "Jebac leszczy",
    "Z lamusami sie nie piescic",
    "Nie ma czasu",
    "I tak wszystkich nie uda Ci sie skreslic",
    "Mam sie strescic? Sluchaj pierwszej czesci, Hemp Gru!",
    "Prosto z ulicy wiesci",
    "Ja i moje ziomk nikt gorszy nikt lepszy",
    "Jestem po to by prawde przyniesc Ci",
    "Policyjne scierwo to WROG NAJWIEKSZY",
    "Twarda bania i zacisniete piesci",
    "Uwalniam instynkt gdy atmosfera sie zagesci",
    "Czekam na waiter co rozgoni czarne chmury",
    "To jest to dzieciak, to jest to co czuje ELO"
};

public plugin_precache()
{
    for (new i = 0; i < sizeof sounds; i++)
        precache_sound(sounds[i]);
}

public plugin_init()
{
    register_plugin("Wilku Admin Sounds", "1.1", "ChatGPT");

    // KOMENDA KONSOLI (bindowalna)
    register_concmd("amx_wilku", "cmd_wilku", ADMIN_FLAG,
        "- otwiera menu Wilku");
}

public cmd_wilku(id)
{
    new menu = menu_create("Wilku – wybierz dzwiek", "menu_handler");

    for (new i = 0; i < sizeof names; i++)
    {
        new num[4];
        num_to_str(i, num, charsmax(num));
        menu_additem(menu, names[i], num);
    }

    menu_display(id, menu);
    return PLUGIN_HANDLED;
}

public menu_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new data[4], access, callback;
    menu_item_getinfo(menu, item, access, data, charsmax(data), _, _, callback);

    new index = str_to_num(data);

    // Odtwarzanie dźwięku dla wszystkich
    client_cmd(0, "spk ^"%s^"", sounds[index]);

    // Tekst na czacie dla wszystkich
    new name[32];
    get_user_name(id, name, charsmax(name));
    client_print(0, print_chat, "[HempGru] %s: %s", name, chat_texts[index]);

    return PLUGIN_HANDLED;
}