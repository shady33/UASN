#include <Timer.h>
#include "TimeSyncCommon.h"

configuration TMsgBeaconAppC{}

implementation
{
	components TMsgBeaconC as App;

	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer2;
	components new TimerMilliC() as Timer3;


	components ActiveMessageC as AM;

  	components LocalTimeMilliC;
	components MainC, LedsC;

	App.Boot -> MainC.Boot;

	App.Send_57_2-> AM.AMSend[AM_TS_57_2];
	App.Send_57_4-> AM.AMSend[AM_TS_57_4];
	App.Send_75_Data-> AM.AMSend[AM_D_75];
	
	App.AMControl -> AM;
	
	App.TSReceive_57_1 ->AM.Receive[AM_TS_57_1];
	App.TSReceive_57_3 ->AM.Receive[AM_TS_57_3];
	App.TSReceive_25_4_2 ->AM.Receive[AM_TS_25_4_2];

	App.Packet -> AM;
	
	App.Timer_57 -> Timer1;
	App.Timer_57_data -> Timer3;
	App.SleepTimer -> Timer2;

	App.Leds ->LedsC;

	App.LocalTime -> LocalTimeMilliC;
}