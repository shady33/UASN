#include "TimeSyncCommon.h"
#include <Timer.h>
#include <UserButton.h>

module TMsgBeaconC @safe()
{
	uses
	{
		interface Leds;
	    interface Boot;

		interface Receive as TSReceive_25_1;
	    interface Receive as TSReceive_25_3;
	    interface Receive as TSReceive_56_2;
	    interface Receive as TSReceive_56_4;
		interface Receive as TSReceive_12_4;

	    interface Receive as DataReceive_65;


	    interface AMSend as Send_25_2;
	    interface AMSend as Send_25_4;
	    interface AMSend as Send_25_4_2; //For the AC calculation that needs to reach the leaf nodes
	    interface AMSend as Send_56_1;
	    interface AMSend as Send_56_3;
	    interface AMSend as Send_52_Data;

	    interface Timer<TMilli> as Timer_25;
	    interface Timer<TMilli> as Timer_56;

	    interface Timer<TMilli> as Timer_Data_52;

	    interface Timer<TMilli> as SleepTimer;

	    interface SplitControl as AMControl;
	    interface Packet;
	    interface LocalTime<TMilli>;
		interface Get<button_state_t>;
	    interface Notify<button_state_t>;
	    interface UartByte;
	}
}

implementation{

	message_t packet, packet_56, packet_57, bpacket, rbpacket, b2packet, dpacket, rpacket_56, rpacket_57;

	data_t* data_msg_52;
	data_t* data_msg_65;


	data_t* data_incoming_65;


	timesync_msg_t* rcm;

	timesync_msg_t* msg_25;
	timesync_msg_t* msg_56;

	timesync_msg_t* rmsg_56;


	timesync_broad_t* rmsg_25;
	timesync_broad_t* rmsg_25_2;
	timesync_broad_t* msg_12;


	uint32_t B1, B2, B3, C1, C2, C3, B2_57, B2_56, AC_slope, AC_offset, AB_slope_int, AB_offset_int;
	uint32_t skew, offset;
	float skewfloat, offsetfloat, AC_slope_float, AC_offset_float, AB_slope, AB_offset;
	int broadcast = 0, data = 0, flag = 0;
	uint16_t count = 0;
	int stage_56 = 1, stage_57 = 1, cyclesleep5 = 200000, syncsleep5, sync6 = 0, sync7 = 0;


	event void Boot.booted(){
		call Notify.enable();
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err){
		if (err == SUCCESS)
		{
			call Timer_Data_52.startOneShot(1680000);
		}
		else
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
  
	event void AMControl.stopDone(error_t err) {
    // do nothing
  	}

  	void sleep(int period)
  	{
  		call SleepTimer.startOneShot(period);
  	}

  	event void SleepTimer.fired()
  	{
  		//Do nothing
  	}

  	event void Timer_56.fired()
  	{
  		if (stage_56 == 1)
  		{
			//Put a clause in the 5-broadcast-overhear that invokes this sending. 

			call Leds.led2Toggle();
			msg_56 = call Packet.getPayload(&packet_56, sizeof(timesync_msg_t));
			msg_56->recv_time = call LocalTime.get();
			msg_56->local_time = call LocalTime.get();
			msg_56->src = TOS_NODE_ID;
			call Send_56_1.send(AM_BROADCAST_ADDR, &packet_56, sizeof(timesync_msg_t)); //Change the sending encapsulator.
			call Timer_56.startOneShot(160000);

		}
		else if (stage_56 == 2)
		{
			call Leds.led1Toggle();
			rmsg_56->local_time = call LocalTime.get();//Replace with packet-level timestamping later
			call Send_56_3.send(AM_BROADCAST_ADDR, &rpacket_56, sizeof(timesync_msg_t));
			call Timer_56.startOneShot(160000);// This is a repeat timer for the second message to be sent to Node3
			
			return;	
		}

  	}

  	event void Timer_Data_52.fired()
  	{
  		//Data being sent upwards to Node 2

			data_msg_52 = (data_t*)call Packet.getPayload(&dpacket, sizeof(data_t));
			data_msg_52->timestamp = call LocalTime.get();

			data_msg_52->data = count;
			data_msg_52->src = TOS_NODE_ID;
			call Send_52_Data.send(AM_BROADCAST_ADDR, &dpacket, sizeof(data_t));

			data = 0;
			count++;
	//		sleep(cyclesleep5);

  	}

	event void Timer_25.fired()
	{
		if (broadcast == 1)
		{
			//TS completion broadcast #1
			call Leds.led0Toggle();
			call Send_25_4.send(AM_BROADCAST_ADDR, &bpacket, sizeof(timesync_broad_t));
			broadcast = 2;
			call Timer_25.startOneShot(70000);
			return;
		}
		else if (broadcast == 2)
		{
			//TS Completion broadcast #2

			call Leds.led0Toggle();
			call Send_25_4_2.send(AM_BROADCAST_ADDR, &b2packet, sizeof(timesync_broad_t));
			broadcast = 0;

			call Timer_56.startOneShot(20000);//(1120 global W.c.)

			

		//	sleep(syncsleep5);
			return;
		}
		else
		{
			//Default: TS reply to Node 2

			C2 = call LocalTime.get();	//time3
			msg_25->local_time = C2;
			call Send_25_2.send(AM_BROADCAST_ADDR, &packet, sizeof(timesync_msg_t));

			call Leds.led0Toggle();
			call Leds.led1Toggle();
			return;
		}
	}

	event message_t* TSReceive_25_1.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		C1 = call LocalTime.get();
		rcm = (timesync_msg_t*) payload;

		B1 = rcm->local_time;
		msg_25 = (timesync_msg_t*)call Packet.getPayload(&packet, sizeof(timesync_msg_t));
        if (msg_25 == NULL) {
        	return bufPtr;  // could not allocate packet
        }
	    msg_25->recv_time = C1;	//time2
        msg_25->src = TOS_NODE_ID;
        
        call Leds.led0Toggle();
        call Timer_25.startOneShot(10000);

        return bufPtr;
	}

	event message_t* TSReceive_25_3.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		C3 = call LocalTime.get();

		rcm = (timesync_msg_t*)payload;

		B2 = rcm -> recv_time;
		B3 = rcm -> local_time;
		//Doing the math
		skewfloat = (float)(((float)C3 - (float)C1)/((float)B3 - (float)B1));
		offsetfloat =(float)(((float)C1 + (float)C2)/2 - ((float)B1 + (float)B2)*skewfloat/2);  

		AC_slope_float = (float)(skewfloat*(float)AB_slope);
		AC_offset_float = (float)(skewfloat*(float)AB_offset) + offsetfloat;		 


		skewfloat = 100000000*skewfloat;
		offsetfloat = 1000*offsetfloat;


		AC_slope_float = 100000000*AC_slope_float;
		AC_offset_float = 1000*AC_offset_float;

		skew = (uint32_t)skewfloat;
		offset = (uint32_t)offsetfloat;

		AC_slope = (uint32_t)AC_slope_float;
		AC_offset = (uint32_t)AC_offset_float;


		//Broadcasting the result to the terrestrial node
		rmsg_25 = (timesync_broad_t*)call Packet.getPayload(&bpacket, sizeof(timesync_broad_t));
        if (rmsg_25 == NULL) {
          return bufPtr;  // could not allocate packet
        }
	    rmsg_25->slope =skew;
        rmsg_25->src = TOS_NODE_ID;
        rmsg_25->offset =offset;

		rmsg_25_2 = (timesync_broad_t*)call Packet.getPayload(&b2packet, sizeof(timesync_broad_t));
        if (rmsg_25_2 == NULL) 
        {
        	return bufPtr;  // could not allocate packet
        }
	    rmsg_25_2->slope =AC_slope;
        rmsg_25_2->src = TOS_NODE_ID;
        rmsg_25_2->offset =AC_offset;

        call Leds.led0Toggle();
        broadcast = 1;
        call Timer_25.startOneShot(10000);

        return bufPtr;
	}

//This is for overhearing on 2's final broadcast so as to get the value of the skew/offset of the first hop
	event message_t* TSReceive_12_4.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		msg_12 =(timesync_broad_t*)payload;
		AB_slope_int = msg_12->slope;
		AB_offset_int = msg_12->offset;

		AB_slope = (float)AB_slope_int;
		AB_offset = (float)AB_offset_int;

		AB_slope =(float)AB_slope/100000000;
		AB_offset = (float)AB_offset/1000;

		call Leds.led1Toggle();
        return bufPtr;
	}

	event message_t* DataReceive_65.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		//No data sending flags are to be set. All data is collected at Node #2 and sent
		//after suitable operations after DataReceive5

		data_msg_65 = (data_t*)call Packet.getPayload(&dpacket, sizeof(data_t));
		data_incoming_65 = (data_t*)payload;

		//Operations to be decided later. This is an illustration.
		data_msg_65->data = (data_incoming_65->data)+2;
		data_msg_65->src = TOS_NODE_ID;

		return bufPtr;
	}

	event message_t* TSReceive_56_2.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		
		B2_56 = call LocalTime.get();

		call Leds.led1Toggle();
		//repeat = 0;
		call Timer_56.stop();
		rcm = (timesync_msg_t*) payload;
		
		//Preparing a reply (third link of the 3Msg protocol)
		rmsg_56 = call Packet.getPayload(&rpacket_56, sizeof(timesync_msg_t));
		rmsg_56->recv_time = B2_56;
		//Send Timestamping done at timer.
		rmsg_56->src = TOS_NODE_ID;

		stage_56 = 2;
		
		call Timer_56.startOneShot(20000);

		return bufPtr;
	}

	event message_t* TSReceive_56_4.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		call Timer_56.stop();
		stage_56 = 1;
		return bufPtr;

	}

	event void Send_25_4.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}

	event void Send_25_2.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}
	event void Send_52_Data.sendDone(message_t* bufPtr, error_t error){
		call Leds.led1Toggle();
		call Leds.led2Toggle();
	}
	event void Send_56_1.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}
	event void Send_56_3.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}
	event void Send_25_4_2.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}


}