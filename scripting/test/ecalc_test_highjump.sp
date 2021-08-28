#include <effectcalc>


public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
	{
		ECalc_Hook("highjump", "base", ModifyStat)
	}
}

public void ModifyStat(any[] data, int size, float &value)
{
	value += 0.1 // +10% jump height
}