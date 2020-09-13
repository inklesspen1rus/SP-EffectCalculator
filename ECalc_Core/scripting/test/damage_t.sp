#include <effectcalc>
#include <cstrike>

public Plugin myinfo = {
	name = "ECalcTest - Damage+ for Terrorists",
	author = "2.0"
}

const float boost = 1.0 // +100%

public void OnPluginStart()
{
	if(LibraryExists("effectcalc"))
		ECalc_Hook2("damage", "base", ModifyDamage)
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		ECalc_Hook2("damage", "base", ModifyDamage)
}

public void ModifyDamage(int client, float &value)
{
	if(GetClientTeam(client) == CS_TEAM_T) // if attacker is T
		value += boost // boost
}