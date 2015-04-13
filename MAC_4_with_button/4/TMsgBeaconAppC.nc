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

	App.Send_24_2-> AM.AMSend[AM_TS_24_2];
	App.Send_24_4-> AM.AMSend[AM_TS_24_4];
	App.Send_42_Data-> AM.AMSend[AM_D_42];
	
	App.AMControl -> AM;
	
	App.TSReceive_24_1 ->AM.Receive[AM_TS_24_1];
	App.TSReceive_24_3 ->AM.Receive[AM_TS_24_3];
	App.TSReceive_12_4 ->AM.Receive[AM_TS_12_4];

	App.Packet -> AM;
	
	App.Timer_24 -> Timer1;
	App.Timer_24_data -> Timer3;
	App.SleepTimer -> Timer2;

	App.Leds ->LedsC;

	App.LocalTime -> LocalTimeMilliC;
}