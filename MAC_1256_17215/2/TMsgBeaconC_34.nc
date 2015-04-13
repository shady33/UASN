#include "TimeSyncCommon.h"
#include <Timer.h>
#include <UserButton.h>


module TMsgBeaconC @safe()
{
	uses
	{
		interface Leds;
	    interface Boot;
	    
	    interface Receive as TSReceive_12_1;
	    interface Receive as TSReceive_12_3;
	    interface Receive as TSReceive_23_2;
	    interface Receive as TSReceive_23_4;
	    interface Receive as TSReceive_24_2;
	    interface Receive as TSReceive_24_4;
	    
	    interface Receive as DataReceive_32;
		interface Receive as DataReceive_42;

	    interface AMSend as Send_12_2;
	    interface AMSend as Send_12_4;
	    interface AMSend as Send_23_1;
	    interface AMSend as Send_23_3;
		interface AMSend as Send_24_1;
	    interface AMSend as Send_24_3;
	    interface AMSend as Send_21_Data;

	    interface Timer<TMilli> as Timer_12;
	    interface Timer<TMilli> as Timer_23;
	    interface Timer<TMilli> as Timer_24;
	    interface Timer<TMilli> as Timer_Data_21;
	    
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

	message_t packet_12, packet_23, packet_24, bpacket_12, dpacket_21, dpacket_42, dpacket_32, rpacket_24, rpacket_23;
	
	data_t* data_msg_21;
	
	data_t* data_msg_32;
	data_t* data_msg_42;
	
	
	data_t* data_incoming_32;
	data_t* data_incoming_42;

	timesync_msg_t* rcm;

	timesync_msg_t* msg_12;
	
	timesync_msg_t* msg_23;
	timesync_msg_t* msg_24;

	timesync_broad_t* rmsg_12;
	
	timesync_msg_t* rmsg_23;
	timesync_msg_t* rmsg_24;


	uint32_t A1, A2, A3, B1, B2, B3, B1p, B2p, B3p, B2_24, B2_23;
	uint32_t skew, offset;
	float skewfloat, offsetfloat;
	int broadcast = 0, mode = 1, reply = 0, broadcount = 0, data = 0, count = 0, count_24 = 0;
	int stage_23 = 1, stage_24 = 1;
	long int cyclesleep2, syncsleep2 = 1040000;

	event void Boot.booted(){
		call Notify.enable();
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err){
		if (err == SUCCESS)
		{
			call Timer_Data_21.startOneShot(1100000);
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

  	void sleep(uint8_t period)
  	{
  		call SleepTimer.startOneShot(period);
  	}
  	
  	//Timer events
  	event void Timer_23.fired()
  	{
		if (stage_23 == 1)
		{
	  		call Leds.led2Toggle();
			msg_23 = call Packet.getPayload(&packet_23, sizeof(timesync_msg_t));
			msg_23->recv_time = call LocalTime.get();
			msg_23->local_time = call LocalTime.get();
			msg_23->src = TOS_NODE_ID;
			call Send_23_1.send(AM_BROADCAST_ADDR, &packet_23, sizeof(timesync_msg_t)); //Change the sending encapsulator.
			call Timer_23.startOneShot(80000);
			count++;
			if (count == 3)
			{
				call Timer_23.stop();
				count = 0;
			}
		}

		if (stage_23 == 2)
		{
			call Leds.led1Toggle();
			rmsg_23->local_time = call LocalTime.get();//Replace with packet-level timestamping later
			call Send_23_3.send(AM_BROADCAST_ADDR, &rpacket_23, sizeof(timesync_msg_t));
			call Timer_23.startOneShot(140000);// This is a repeat timer for the second message to be sent to Node3
			count++;
			if (count == 3)
			{
				call Timer_23.stop();
				count = 0;
			}
			
			return;
		}
  	}

  	event void Timer_24.fired()
  	{
  		if (stage_24 == 1)
  		{
			call Timer_23.stop();
  			call Leds.led2Toggle();
			msg_24 = call Packet.getPayload(&packet_24, sizeof(timesync_msg_t));
			msg_24->recv_time = call LocalTime.get();
			msg_24->local_time = call LocalTime.get();
			msg_24->src = TOS_NODE_ID;
			call Send_24_1.send(AM_BROADCAST_ADDR, &packet_24, sizeof(timesync_msg_t)); //Change the sending encapsulator.
			call Timer_24.startOneShot(80000);
			count_24++;
			if (count_24 == 3)
			{
				call Timer_24.stop();
				count_24 = 0;
			}

  		}

  		if (stage_24 == 2)
  		{
  			call Leds.led1Toggle();
			rmsg_24->local_time = call LocalTime.get();//Replace with packet-level timestamping later
			call Send_24_3.send(AM_BROADCAST_ADDR, &rpacket_24, sizeof(timesync_msg_t));
			call Timer_24.startOneShot(140000);// This is a repeat timer for the second message to be sent to Node3
			
			count_24++;
			if (count_24 == 3)
			{
				call Timer_24.stop();
				count_24 = 0;
			}
			sleep(syncsleep2);
			return;
  		}
  	}

  	event void Timer_Data_21.fired()
  	{
		data_msg_21->timestamp = call LocalTime.get();
		call Send_21_Data.send(AM_BROADCAST_ADDR, &dpacket_21, sizeof(data_t));
		data = 0;
		
		sleep(cyclesleep2);
		return;	
  	}

  	event void SleepTimer.fired()
  	{
  		//Do nothing
  	}


	event void Timer_12.fired()
	{
		if (broadcast == 1)
		{
			//Send data to the listener node.

			broadcount++;
			call Leds.led0Toggle();
			call Send_12_4.send(AM_BROADCAST_ADDR, &bpacket_12, sizeof(timesync_broad_t));
			if (broadcount%2 == 0)
			{	
				broadcast = 0;
			

			//*************************************Sequential************************
			call Timer_24.startOneShot(360000);//(1900)
			call Timer_23.startOneShot(40000);//(1320)
			//call Timer_Data_21.startOneShot(3440000 + 310000 + 100000);//(4100000)(310 for best case and 100 padding)
			}
			else	
				call Timer_12.startOneShot(30000);
			return;
		}

		else
		{
			//Default case - reply to Node 1 for mHS.

			B2 = call LocalTime.get();	//time3
			msg_12->local_time = B2;
			call Send_12_2.send(AM_BROADCAST_ADDR, &packet_12, sizeof(timesync_msg_t));
			call Leds.led0Toggle();
			call Leds.led1Toggle();
			return;

		}
	}

	event message_t* TSReceive_12_1.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		B1 = call LocalTime.get();
		rcm = (timesync_msg_t*) payload;
		call Timer_12.stop();

		A1 = rcm->local_time;
		msg_12 = (timesync_msg_t*)call Packet.getPayload(&packet_12, sizeof(timesync_msg_t));
        if (msg_12 == NULL) {
        	return bufPtr;  // could not allocate packet
        }
	    msg_12->recv_time = B1;	//time2
        msg_12->src = TOS_NODE_ID;
        
        call Leds.led0Toggle();
        call Timer_12.startOneShot(10000);

        return bufPtr;
	}

	event message_t* TSReceive_12_3.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		B3 = call LocalTime.get();
		call Timer_12.stop();
		rcm = (timesync_msg_t*) payload;

		A2 = rcm -> recv_time;
		A3 = rcm -> local_time;

		//Doing the math
		skewfloat = (float)(((float)B3 - (float)B1)/((float)A3 - (float)A1));
		offsetfloat =(float)(((float)B1 + (float)B2)/2 - ((float)A1 + (float)A2)*skewfloat/2);  

		skewfloat = 100000000*skewfloat;
		offsetfloat = 1000*offsetfloat;

		skew = (uint32_t)skewfloat;
		offset = (uint32_t)offsetfloat;


		//Broadcasting the result to the terrestrial node
		rmsg_12 = (timesync_broad_t*)call Packet.getPayload(&bpacket_12, sizeof(timesync_broad_t));
        if (rmsg_12 == NULL) {
        	return bufPtr;  // could not allocate packet
        }
	    rmsg_12->slope =skew;
        rmsg_12->src = TOS_NODE_ID;
        rmsg_12->offset =offset;
        call Leds.led0Toggle();
        broadcast = 1;

        call Timer_12.startOneShot(10000);
        return bufPtr;
	}
	
	event message_t* TSReceive_23_2.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		
		B2_23 = call LocalTime.get();

		call Leds.led1Toggle();

		call Timer_23.stop();
		rcm = (timesync_msg_t*) payload;
		
		//Preparing a reply (third link of the 3Msg protocol)
		rmsg_23 = call Packet.getPayload(&rpacket_23, sizeof(timesync_msg_t));
		rmsg_23->recv_time = B2_23;
		//Send Timestamping done at timer.
		rmsg_23->src = TOS_NODE_ID;
		
		stage_23 = 2;
		
		call Timer_23.startOneShot(10000);
		count = 0;
		return bufPtr;
	}

	event message_t* TSReceive_24_2.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
			
		B2_24 = call LocalTime.get();

		call Leds.led1Toggle();

		call Timer_24.stop();
		rcm = (timesync_msg_t*) payload;
		
		//Preparing a reply (third link of the 3Msg protocol)
		rmsg_24 = call Packet.getPayload(&rpacket_24, sizeof(timesync_msg_t));
		rmsg_24->recv_time = B2_24;
		//Send Timestamping done at timer.
		rmsg_24->src = TOS_NODE_ID;

		stage_24 = 2;
		count_24 = 0;
		call Timer_24.startOneShot(10000);

		return bufPtr;
	}

	event message_t* TSReceive_24_4.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		call Timer_24.stop();
		count_24 = 0;
		return bufPtr;
	}

	event message_t* TSReceive_23_4.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		call Timer_23.stop();
		count = 0;
		return bufPtr;
	}

	event message_t* DataReceive_42.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		//No data sending flags are to be set. All data is collected at Node #2 and sent
		//after suitable operations after DataReceive5
		
		call Timer_24.stop();
		data_msg_42 = (data_t*)call Packet.getPayload(&dpacket_42, sizeof(data_t));
		data_incoming_42 = (data_t*)payload;

		//Operations to be decided later. This is an illustration.
		data_msg_42->data = (data_incoming_42->data)+2;
		data_msg_42->src = TOS_NODE_ID;

		return bufPtr;
	}

	event message_t* DataReceive_32.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		//No data sending flags are to be set. All data is collected at Node #2 and sent
		//after suitable operations after DataReceive5

		data_msg_32 = (data_t*)call Packet.getPayload(&dpacket_32, sizeof(data_t));
		data_incoming_32 = (data_t*)payload;

		//Operations to be decided later. This is an illustration.
		data_msg_32->data = (data_incoming_32->data)+2;
		data_msg_32->src = TOS_NODE_ID;

		data_msg_21 = (data_t*)call Packet.getPayload(&dpacket_21, sizeof(data_t));
		//Do operations here on data from 52, 32 and 42 

		return bufPtr;
	}

	event void Send_12_2.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}


	event void Send_12_4.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}

	event void Send_23_1.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}
	event void Send_24_1.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}
	event void Send_23_3.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}
	event void Send_24_3.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}

	event void Send_21_Data.sendDone(message_t* bufPtr, error_t error){
		call Leds.led1Toggle();
		call Leds.led2Toggle();
	}
}
