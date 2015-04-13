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

	components ActiveMessageC as AM;

  	components LocalTimeMilliC;
	components MainC, LedsC;

	components PlatformSerialC;
	components UserButtonC;
	App.Get->UserButtonC;
	App.Notify->UserButtonC;
	App.UartByte -> PlatformSerialC;

	App.Boot -> MainC.Boot;
	App.AMControl -> AM;
	App.Packet -> AM;

	App.Send_12_2 -> AM.AMSend[AM_TS_12_2];
	App.Send_12_4 -> AM.AMSend[AM_TS_12_4];
	App.Send_25_1 -> AM.AMSend[AM_TS_25_1];
	App.Send_25_3 -> AM.AMSend[AM_TS_25_3];
	App.Send_21_Data -> AM.AMSend[AM_D_21];

	App.TSReceive_12_1 ->AM.Receive[AM_TS_12_1];
	App.TSReceive_12_3 ->AM.Receive[AM_TS_12_3];
	App.TSReceive_25_2 ->AM.Receive[AM_TS_25_2];
	App.TSReceive_25_4 ->AM.Receive[AM_TS_25_4];

	App.DataReceive_52 ->AM.Receive[AM_D_52];		
	
	App.Timer_12 -> Timer1;
	App.Timer_25 -> Timer4;
	App.Timer_Data_21 -> Timer6;
	App.SleepTimer -> Timer5;

	App.Leds ->LedsC;

	App.LocalTime -> LocalTimeMilliC;
}