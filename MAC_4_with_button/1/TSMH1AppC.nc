#include <Timer.h>
#include "TimeSyncCommon.h"

configuration TSMH1AppC{}

implementation
{
	components TSMH1C as App;
	components new TimerMilliC() as Timer1;
	components new TimerMilliC() as Timer2;
	components new TimerMilliC() as Timer3;

	components ActiveMessageC as AM;
  	components LocalTimeMilliC;
	components MainC, LedsC;
	
	components PlatformSerialC;
	components UserButtonC;
	App.Get->UserButtonC;
	App.Notify->UserButtonC;
	App.UartByte -> PlatformSerialC;

	App.Boot -> MainC.Boot;
	App.Send_12_1 -> AM.AMSend[AM_TS_12_1];
	App.Send_12_3 -> AM.AMSend[AM_TS_12_3];
	App.Send_1_Broad -> AM.AMSend[AM_D_1B];
	App.AMControl -> AM;
	
	
	App.TSReceive_12_4 ->AM.Receive[AM_TS_12_4];
	App.TSReceive_12_2 ->AM.Receive[AM_TS_12_2];
	App.DataReceive_21 ->AM.Receive[AM_D_21];

	App.Packet -> AM;
	App.Timer_12 -> Timer1;
	App.CycleTimer -> Timer2;
	App.SleepTimer -> Timer3;

	App.Leds ->LedsC;

	App.LocalTime -> LocalTimeMilliC;
}