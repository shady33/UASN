#include <Timer.h>
#include "TimeSyncCommon.h"

configuration TMsgBeaconAppC{}

implementation
{
	components TMsgBeaconC as App;

	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer2;
	components new TimerMilliC() as Timer3;

	components SerialActiveMessageC as AM;

  	components LocalTimeMilliC;
	components MainC, LedsC;

	App.Boot -> MainC.Boot;

	App.Send_23_2-> AM.AMSend[AM_TS_23_2];
	App.Send_23_4-> AM.AMSend[AM_TS_23_4];
	App.Send_32_Data-> AM.AMSend[AM_D_32];
	
	App.AMControl -> AM;
	
	App.TSReceive_23_1 ->AM.Receive[AM_TS_23_1];
	App.TSReceive_23_3 ->AM.Receive[AM_TS_23_3];
	App.TSReceive_12_4 ->AM.Receive[AM_TS_12_4];

	App.Packet -> AM;
	
	App.Timer_23 -> Timer1;
	App.Timer_23_data -> Timer3;
	App.SleepTimer -> Timer2;

	App.Leds ->LedsC;

	App.LocalTime -> LocalTimeMilliC;
}