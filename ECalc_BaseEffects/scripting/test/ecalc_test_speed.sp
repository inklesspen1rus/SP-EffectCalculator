#include <effectcalc>

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
	{
		ECalc_Hook("speed", "base", ModifyStat)
	}
}

public void ModifyStat(any[] data, int size, float &value)
{
	value += 0.333333 // +33.3333%
}