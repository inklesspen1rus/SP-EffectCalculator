#include <effectcalc>

public Plugin myinfo = {
	name = "ECalcTest - Damage+ by fire",
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

public void ModifyDamage(int client, float &value, const char[] effect, any[] data, int size)
{
	if(data[3] & ((1 << 3)|(1 << 24))) // DMG_BURN|DMG_PLASMA
	{
		value += boost
	}
}