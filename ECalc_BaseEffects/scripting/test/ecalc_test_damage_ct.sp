#include <effectcalc>

public void OnPluginStart()
{
	if(LibraryExists("effectcalc"))
	{
		ECalc_Hook("damage", "base", ModifyStat)
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
	{
		ECalc_Hook("damage", "base", ModifyStat)
	}
}

public void ModifyStat(any[] data, int size, float &value)
{
	if(0 < data[1] <= MaxClients && GetClientTeam(data[1]) == 3)
		value += 0.2 // +20% damage
}