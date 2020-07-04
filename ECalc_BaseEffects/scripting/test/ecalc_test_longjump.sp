#include <effectcalc>

public void OnPluginStart()
{
	if(LibraryExists("effectcalc"))
	{
		ECalc_Hook("longjump", "base", ModifyStat)
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
	{
		ECalc_Hook("longjump", "base", ModifyStat)
	}
}

public void ModifyStat(any[] data, int size, float &value)
{
	value += 0.333333 // +33.3333%
}