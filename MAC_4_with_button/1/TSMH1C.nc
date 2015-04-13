#include "TimeSyncCommon.h"
#include <Timer.h>
#include <UserButton.h>

/*This code starts off with a timesync cycle. Then it waits for data to come its way in the opposite direction.
The intermediate time is considered to be a sleep period which currently does nothing.

*/


module TSMH1C @safe()
{
	uses
	{
		interface Leds;
	    interface Boot;
	    interface Receive as TSReceive_12_2;
	    interface Receive as TSReceive_12_4;
	    interface Receive as DataReceive_21; 

	    interface AMSend as Send_12_1;
	    interface AMSend as Send_12_3;
	    interface AMSend as Send_1_Broad;
	    
	    interface Timer<TMilli> as Timer_12;
	    interface Timer<TMilli> as CycleTimer;
	    interface Timer<TMilli> as SleepTimer;

	    interface SplitControl as AMControl;
	    interface Packet;
	    interface LocalTime<TMilli>;
	    interface UartByte;
	    interface Get<button_state_t>;
	    interface Notify<button_state_t>;
	}
}
implementation{

	timesync_msg_t* msg;
	timesync_msg_t* rcm;
	timesync_msg_t* rmsg;
	timesync_broad_t* bmsg;
	
	data_t* data_msg;
	data_t* data_incoming;

	message_t packet, bpacket, rpacket, dpacket; 
	uint32_t A1,A2,A3;
	int repeat = 1,reply = 0, data = 0;

	long int syncsleep = 16300000, cyclesleep;
	long int cyclePeriod = 7200000;//120 mins. For now. 10 for the mHS, 3*4 = 12 for the TS, 6 min for data. 32 min sleep.  


	void sleep(uint8_t period)
	{
		call SleepTimer.startOneShot(period);
		//Do nothing.
	}

	event void Boot.booted(){
		call Notify.enable();
		call AMControl.start();
	}

  event void Notify.notify( button_state_t state ) {
    if ( state == BUTTON_PRESSED ) {
      call Leds.led2Toggle();
      call UartByte.send('a');
    } else if ( state == BUTTON_RELEASED ) {
      call Leds.led2Toggle();
    }
  }

	event void AMControl.startDone(error_t err){
		if (err == SUCCESS)
		{
			call Timer_12.startOneShot(160000);
			call CycleTimer.startPeriodic(cyclePeriod);
		}
	}

	event void AMControl.stopDone(error_t err) {
    // do nothing
  	}

  	event void CycleTimer.fired()
  	{
  		reply = 0;
  		data = 0;
  		call Timer_12.startOneShot(160000);
  	}


  	event void SleepTimer.fired()
  	{
  		//Do nothing.
  	}

	event void Timer_12.fired()
	{
		
		if (reply == 1)
		{
			//Second phase of TriMessage mHS
			call Leds.led1Toggle();
			rmsg->local_time = call LocalTime.get();//Replace with packet-level timestamping later
			call Send_12_3.send(AM_BROADCAST_ADDR, &rpacket, sizeof(timesync_msg_t));
			call Timer_12.startOneShot(160000);//Let this repeat; stop timer in BroadSend2 receipt.
			
			sleep(syncsleep);
			return;	
		}
		else if (data == 1)
		{
			//Data relay upwards.Currently triggered by an event; will have to implement sleep timer later.
			data_msg->timestamp = call LocalTime.get();
			call Send_1_Broad.send(AM_BROADCAST_ADDR, &dpacket, sizeof(data_t));
			data = 0;

			//The sleep at the end of this data travel is handled by the CycleTimer, so no need to call sleep(cyclesleep).
			return;
		}
		else
		{

			//TriMessage mHS first phase
			call Leds.led2Toggle();
			msg = call Packet.getPayload(&packet, sizeof(timesync_msg_t));
			msg->recv_time = call LocalTime.get();
			msg->local_time = call LocalTime.get();
			msg->src = TOS_NODE_ID;
			call Send_12_1.send(AM_BROADCAST_ADDR, &packet, sizeof(timesync_msg_t));
			call Timer_12.startOneShot(160000);

			return;
		}
	}

	event message_t* TSReceive_12_2.receive(message_t* bufPtr, void* payload, uint8_t len)
	{

		A2 = call LocalTime.get();

		call Leds.led1Toggle();
		repeat = 0;
		call Timer_12.stop();
		rcm = (timesync_msg_t*) payload;
		
		//Preparing a reply (third link of the 3Msg protocol)
		rmsg = call Packet.getPayload(&rpacket, sizeof(timesync_msg_t));
		rmsg->recv_time = A2;
		//Send Timestamping done at timer.
		rmsg->src = TOS_NODE_ID;

		reply = 1;
		call Timer_12.startOneShot(20000);

		return bufPtr;

	}
	
	//Wired to BroadSend2
	event message_t* TSReceive_12_4.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		//Acknowledgement for mHS completion.
		call Timer_12.stop();
		reply = 0;

		return bufPtr;
	}

	event message_t* DataReceive_21.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		//Data receipt from lower layer. Event based, but nodes can sleep for syncsleep time
		//and wake up just a few seconds before this data receipt.

		data_msg = (data_t*)call Packet.getPayload(&dpacket, sizeof(data_t));
		data_incoming = (data_t*)payload;

		data_msg->data = (data_incoming->data)+2;
		data_msg->src = TOS_NODE_ID;

		data = 1;
		call Timer_12.startOneShot(10000);

		return bufPtr;
	}

	event void Send_12_3.sendDone(message_t* bufPtr, error_t error) {}
	event void Send_12_1.sendDone(message_t* bufPtr, error_t error) {}
	event void Send_1_Broad.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}
}