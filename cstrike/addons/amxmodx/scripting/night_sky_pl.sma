#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Night Sky Manager"
#define VERSION "1.0"
#define AUTHOR "Mili 1"

// Zmienne globalne
new g_iCurrentSky = 0; // 0 = dzień, 1 = noc
new g_iTaskID = 12345;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// Ustawiamy czas na start serwera
	check_sky_time();
	
	// Tworzymy timer który sprawdza czas co 60 sekund
	set_task(60.0, "check_sky_time", g_iTaskID, _, _, "b");
}

public check_sky_time()
{
	// Pobieramy aktualny czas
	new iHour = get_systime() / 3600 % 24;
	
	// Sprawdzamy czy jest noc (16:00-23:59 lub 00:00-07:59)
	new bIsNight = (iHour >= 16 || iHour < 8) ? 1 : 0;
	
	// Jeśli zmieniła się pora dnia - zmieniamy niebo
	if(bIsNight != g_iCurrentSky)
	{
		g_iCurrentSky = bIsNight;
		
		if(bIsNight)
		{
			// Ustawiamy nocne niebo
			server_cmd("sv_skyname space");
			server_print("[Night Sky] Włączono nocne niebo (godzina: %02d:00)", iHour);
		}
		else
		{
			// Ustawiamy dzienne niebo
			server_cmd("sv_skyname day");
			server_print("[Night Sky] Włączono dzienne niebo (godzina: %02d:00)", iHour);
		}
		
		// Powiadamiamy graczy
		client_print(0, print_chat, "[Night Sky] Zmiana nieba na %s", bIsNight ? "nocne" : "dzienne");
	}
}

public plugin_end()
{
	// Usuwamy zadanie na koniec serwera
	remove_task(g_iTaskID);
}
