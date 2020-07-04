#include <effectcalc>

public Plugin myinfo = {
	name = "ECalcTest - Speed+ for Terrorists",
	author = "1.0"
}

const float boost = 0.2 

public void OnPluginStart()
{
	if(LibraryExists("effectcalc"))
		ECalc_Hook("speed", "base", ModifySpeed)
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		ECalc_Hook("speed", "base", ModifySpeed)
}

public void ModifySpeed(any[] data, int size, float &value)
{
	if(size && 0 < data[0] <= MaxClients && GetClientTeam(data[0]) == 2)
	{
		value += boost
	}
}