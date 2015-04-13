#include <Timer.h>
#include "TimeSyncCommon.h"

configuration TMsgBeaconAppC{}

implementation
{
	components TMsgBeaconC as App;
	
	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer4;
	components new TimerMilliC() as Timer5;
	components new TimerMilliC() as Timer6;
	components new TimerMilliC() as Timer7;

	components ActiveMessageC as AM;

  	components LocalTimeMilliC;
	components MainC, LedsC;
	components SerialStartC;
	components PlatformSerialC;

	components UserButtonC;
	App.UartByte->PlatformSerialC;
	App.Get->UserButtonC;
	App.Notify->UserButtonC;

	App.Boot -> MainC.Boot;
	App.AMControl -> AM;
	App.Packet -> AM;

	App.Send_12_2 -> AM.AMSend[AM_TS_12_2];
	App.Send_12_4 -> AM.AMSend[AM_TS_12_4];
	App.Send_23_1 -> AM.AMSend[AM_TS_23_1];
	App.Send_23_3 -> AM.AMSend[AM_TS_23_3];
	App.Send_24_1 -> AM.AMSend[AM_TS_24_1];
	App.Send_24_3 -> AM.AMSend[AM_TS_24_3];
	App.Send_21_Data -> AM.AMSend[AM_D_21];

	App.TSReceive_12_1 ->AM.Receive[AM_TS_12_1];
	App.TSReceive_12_3 ->AM.Receive[AM_TS_12_3];
	App.TSReceive_23_2 ->AM.Receive[AM_TS_23_2];
	App.TSReceive_23_4 ->AM.Receive[AM_TS_23_4];
	App.TSReceive_24_2 ->AM.Receive[AM_TS_24_2];
	App.TSReceive_24_4 ->AM.Receive[AM_TS_24_4];


	App.DataReceive_42 ->AM.Receive[AM_D_42];		
	App.DataReceive_32 ->AM.Receive[AM_D_32];		
	
	App.Timer_12 -> Timer1;
	App.Timer_23 -> Timer4;
	App.Timer_24 -> Timer7;
	App.Timer_Data_21 -> Timer6;
	App.SleepTimer -> Timer5;

	App.Leds ->LedsC;

	App.LocalTime -> LocalTimeMilliC;
}
