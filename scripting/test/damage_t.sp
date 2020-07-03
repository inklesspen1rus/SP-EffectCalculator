#include <effectcalc>

const float boost = 1.0 // +100%

public void OnPluginStart()
{
	if(LibraryExists("effetcalc"))
		ECalc_Hook("damage", "base", ModifyDamage)
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		ECalc_Hook("damage", "base", ModifyDamage)
}

public void ModifyDamage(any[] data, int size, float &value)
{
	// see data struct in effect_damage.sp
	if(0 < data[1] <= MaxClients & GetClientTeam(data[1])) // if attacker is terrorist
	{
		value += boost
	}
}