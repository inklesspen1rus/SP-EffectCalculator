#include <effectcalc>

public Plugin myinfo = {
	name = "ECalcTest - Speed+ for Terrorists",
	author = "2.0"
}

const float boost = 0.2 

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		ECalc_Hook2("speed", "base", ModifySpeed)
}

public void ModifySpeed(int client, float &value)
{
	if(GetClientTeam(client) == 2)
	{
		value += boost
	}
}