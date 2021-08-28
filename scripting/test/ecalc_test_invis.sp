#include <effectcalc>

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
	{
		ECalc_Hook("invis", "base", ModifyStat)
	}
}

public void ModifyStat(any[] data, int size, float &value)
{
	value += 1.0 // +100%
}