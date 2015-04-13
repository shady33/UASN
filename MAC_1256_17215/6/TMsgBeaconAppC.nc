#include <Timer.h>
#include "TimeSyncCommon.h"

configuration TMsgBeaconAppC{}

implementation
{
	components TMsgBeaconC as App;

	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer2;
	components new TimerMilliC() as Timer3;
    components new TimerMilliC() as Timer4;


	components ActiveMessageC as AM;

  	components LocalTimeMilliC;
	components MainC, LedsC;

	components PlatformSerialC;
//	components UserButtonC;
//	App.Get->UserButtonC;
//	App.Notify->UserButtonC;
//	App.UartByte -> PlatformSerialC;
	
	App.Boot -> MainC.Boot;

	App.Send_56_2-> AM.AMSend[AM_TS_56_2];
	App.Send_56_4-> AM.AMSend[AM_TS_56_4];
	App.Send_65_Data-> AM.AMSend[AM_D_65];
	
	App.AMControl -> AM;
	
	App.TSReceive_56_1 ->AM.Receive[AM_TS_56_1];
	App.TSReceive_56_3 ->AM.Receive[AM_TS_56_3];
	App.TSReceive_25_4_2 ->AM.Receive[AM_TS_25_4_2];

	App.Packet -> AM;
	
	App.Timer_56 -> Timer1;
	App.Timer_56_data -> Timer3;
	App.SleepTimer -> Timer2;
   // App.Timer_waittillmsg->Timer4;
	App.Leds ->LedsC;

	App.LocalTime -> LocalTimeMilliC;
}