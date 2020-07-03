#include <effectcalc>

const float boost = 1.0 // +100%

public void OnPluginStart()
{
	if(LibraryExists("effectcalc"))
		ECalc_Hook("damage", "base", ModifyDamage)
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		ECalc_Hook("damage", "base", ModifyDamage)
}

public void ModifyDamage(any[] data, int size, float &value)
{
	if(data[4] & ((1 << 3)|(1 << 24))) // DMG_BURN|DMG_PLASMA
	{
		value += boost
	}
}