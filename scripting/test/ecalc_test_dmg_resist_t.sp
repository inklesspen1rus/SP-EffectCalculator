#include <effectcalc>

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
	{
		ECalc_Hook("dmgresist", "base", ModifyStat)
	}
}

public void ModifyStat(any[] data, int size, float &value)
{
	if(0 < data[0] <= MaxClients && GetClientTeam(data[0]) == 2) // for T
		value += 0.5 // +50% damage resistance 
}