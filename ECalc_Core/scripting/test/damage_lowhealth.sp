#include <effectcalc>

public Plugin myinfo = {
	name = "ECalcTest - Damage+ on low health",
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
	if(GetClientHealth(client) <= 50) // if attacker has 50 or less hp
		value += boost
}