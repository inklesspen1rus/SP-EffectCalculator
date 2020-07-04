#include <effectcalc>

public void OnPluginStart()
{
	if(LibraryExists("effectcalc"))
	{
		ECalc_Hook("damage", "resistance", ModifyStat)
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
	{
		ECalc_Hook("damage", "resistance", ModifyStat)
	}
}

public void ModifyStat(any[] data, int size, float &value)
{
	if(0 < data[0] <= MaxClients && GetClientTeam(data[0]) == 2)
		value /= (1.0 + 0.5) // +50% damage resistance 
}