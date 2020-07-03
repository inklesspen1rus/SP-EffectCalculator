//------------------------------------------------------------------------------
// GPL LICENSE (short)
//------------------------------------------------------------------------------
/*
 * Copyright (c) 2020 R1KO, vadrozh

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_functions>
#include <vip_core>
#undef REQUIRE_PLUGIN
#include <effectcalc>

#define VIP_SPEED	"Speed"

// включен effectcalc или нет
bool UseECalc = false;

// ID эффекта для просчета скорости
int effect = -1;

public Plugin myinfo =
{
	name = "[VIP] Speed (Effect Calc support)",
	author = "R1KO, vadrozh (ecalc support by inklesspen)",
	description = "Увеличение скорости VIP игроков",
	version = "1.2.0",
	url = "https://hlmod.ru"
};

int m_flLaggedMovementValue;

public void OnPluginStart()
{
	m_flLaggedMovementValue = FindSendPropInfo("CCSPlayer", "m_flLaggedMovementValue");
	
	if (!m_flLaggedMovementValue)
		SetFailState("Unable to get m_flLaggedMovementValue offset");
	
	if(VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();
	
	// проверяем effectcalc при старте плагина
	if(LibraryExists("effectcalc")) // если включен
	{
		UseECalc = true; // обновляем переменную
		ECalc_Hook("speed", "vip", ModifySpeed_Mult); // ловим просчет скорости отдельно, для умножения
		ECalc_Hook("speed", "base", ModifySpeed_Add); // и общее, для сложения
		effect = ECalc_GetEffect("speed"); // Регистрируем/получаем эффект скорости
	}
}

public void OnLibraryAdded(const char[] name) // если библиотека была добавлена
{
	if(!strcmp(name, "effectcalc")) // и библиотека = effectcalc
	{
		UseECalc = true; // обновляем переменную
		ECalc_Hook("speed", "vip", ModifySpeed_Mult); // ловим просчет скорости отдельно, для умножения
		ECalc_Hook("speed", "base", ModifySpeed_Add); // и общее, для сложения
		effect = ECalc_GetEffect("speed"); // Регистрируем/получаем эффект скорости
	}
}

public void OnLibraryRemoved(const char[] name) // если библиотека была удалена
{
	if(!strcmp(name, "effectcalc")) // и это effectcalc
		UseECalc = false; // обновляем переменную, плагин будет работать в штатном режиме
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterMe") == FeatureStatus_Available)
		VIP_UnregisterMe();
}

public void VIP_OnVIPLoaded() { VIP_RegisterFeature(VIP_SPEED, STRING, _, VIP_OnFeatureToggle); }

public void VIP_OnPlayerSpawn(int iClient, int iTeam, bool bIsVIP)
{
	if(bIsVIP && VIP_IsClientFeatureUse(iClient, VIP_SPEED))
		GiveSpeed(iClient);
}

public Action VIP_OnFeatureToggle(int iClient, const char[] szFeature, VIP_ToggleState eOldStatus, VIP_ToggleState &eNewStatus)
{
	if (eNewStatus == ENABLED)
		GiveSpeed(iClient);
	else
		SetEntDataFloat(iClient, m_flLaggedMovementValue, 1.0, true);

	return Plugin_Continue;
}

void GiveSpeed(int iClient)
{
	if(UseECalc) // если включен effectcalc, используем его
	{
		int temp[1]; // Создаем временный массив с размером 1
		temp[0] = iClient; // записываем туда игрока
		SetEntDataFloat(iClient, m_flLaggedMovementValue, ECalc_Run(effect, temp, 1), true); // выставляем игроку скорость, просчитанную с помощью Effect Calculator, на случай, если стоит effect_speed
	}
		
	char sSpeed[16];
	float fSpeed;
	VIP_GetClientFeatureString(iClient, VIP_SPEED, sSpeed, sizeof(sSpeed));
	if(sSpeed[0] == '+')
		fSpeed = StringToFloat(sSpeed[2]) + GetEntDataFloat(iClient, m_flLaggedMovementValue);
	else
		StringToFloatEx(sSpeed, fSpeed);
	SetEntDataFloat(iClient, m_flLaggedMovementValue, fSpeed, true);
}

float GetSpeed(int iClient, bool base)
{
	char sSpeed[16];
	VIP_GetClientFeatureString(iClient, VIP_SPEED, sSpeed, sizeof(sSpeed));
	if(sSpeed[0] == '+') // Если значение начинается с +
	{
		if(base) // и требуем скорость для сложения
			return StringToFloat(sSpeed[2]); // возвращаем значение
	}
	else if(!base) // если значение обычное и требуем скорость для умножения
		return StringToFloat(sSpeed)-1.0; // возвращаем значение - 1.0 (т.к. изначальное значение уже 1.0)
	return 0.0;
}

public void ModifySpeed_Mult(any[] data, int size, float &value) // просчет скорости игрока, отдельное умножение
{
	if(size && 0 < data[0] <= MaxClients)
	{
		int iClient = data[0]; // выводим из общего массива данных клиента
		if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, VIP_SPEED))
			value += GetSpeed(iClient, false); // умножаем общую скорость
	}
}

public void ModifySpeed_Add(any[] data, int size, float &value) // просчет скорости игрока, сложение значений
{
	if(size && 0 < data[0] <= MaxClients)
	{
		int iClient = data[0]; // выводим из общего массива данных клиента
		if(VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, VIP_SPEED)) // если игрок - вип, и функция скорости активна
			value += GetSpeed(iClient, true); // прибавляем скорость к общему множителю
	}
}