#include <Timer.h>
#include "TimeSyncCommon.h"

configuration TMsgBeaconAppC{}

implementation
{
	components TMsgBeaconC as App;
	
	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer2;
	components new TimerMilliC() as Timer4;
	components new TimerMilliC() as Timer5;
    components new TimerMilliC() as Timer6;

	components ActiveMessageC as AM;

  	components LocalTimeMilliC;
	components MainC, LedsC;

	components PlatformSerialC;
//	components UserButtonC;
//	App.Get->UserButtonC;
//	App.Notify->UserButtonC;
//	App.UartByte -> PlatformSerialC;
	
	App.Boot -> MainC.Boot;
	App.AMControl -> AM;

	App.Send_25_2 -> AM.AMSend[AM_TS_25_2];
	App.Send_25_4 -> AM.AMSend[AM_TS_25_4];
	App.Send_25_4_2 -> AM.AMSend[AM_TS_25_4_2];
	App.Send_56_1 -> AM.AMSend[AM_TS_56_1];
	App.Send_56_3 -> AM.AMSend[AM_TS_56_3];
	App.Send_52_Data -> AM.AMSend[AM_D_52];

	App.TSReceive_25_1 ->AM.Receive[AM_TS_25_1];
	App.TSReceive_25_3 ->AM.Receive[AM_TS_25_3];
	App.TSReceive_56_2 ->AM.Receive[AM_TS_56_2];
	App.TSReceive_56_4 ->AM.Receive[AM_TS_56_4];

	App.DataReceive_65 ->AM.Receive[AM_D_65];
	
	App.Packet -> AM;
	App.Timer_25 -> Timer1;
	App.Timer_56 -> Timer2;
	App.Timer_Data_52 -> Timer4;

	App.SleepTimer -> Timer5;
	App.Timer_Waitfor6-> Timer6;

	App.Leds ->LedsC;

	App.LocalTime -> LocalTimeMilliC;
}