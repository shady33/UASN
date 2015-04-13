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
	    interface Receive as TSReceive_25_2;
	    interface Receive as TSReceive_25_4;
	    
		interface Receive as DataReceive_52;

	    interface AMSend as Send_12_2;
	    interface AMSend as Send_12_4;
	    interface AMSend as Send_25_1;
	    interface AMSend as Send_25_3;
	    interface AMSend as Send_21_Data;

	    interface Timer<TMilli> as Timer_12;
	    interface Timer<TMilli> as Timer_25;
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

	message_t packet_12, packet_23, packet_24, packet_25, bpacket_12, rpacket_25, dpacket_21, dpacket_52, dpacket_42, dpacket_32, rpacket_24, rpacket_23;
	
	data_t* data_msg_21;
	data_t* data_msg_52;
	
	data_t* data_incoming_52;

	timesync_msg_t* rcm;

	timesync_msg_t* msg_12;
	timesync_msg_t* msg_25;

	timesync_broad_t* rmsg_12;
	timesync_msg_t* rmsg_25;


	uint32_t A1, A2, A3, B1, B2, B3, B1p, B2p, B3p, B2_24, B2_23;
	uint32_t skew, offset;
	float skewfloat, offsetfloat;
	int broadcast = 0, mode = 1, reply = 0, broadcount = 0, data = 0;
	int stage_23 = 1, stage_24 = 1, stage_25 = 1;
	long int cyclesleep2, syncsleep2 = 1040000;

	event void Boot.booted(){
		call Notify.enable();
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err){
		if (err == SUCCESS)
		{
			//call Timer_Data_21.startOneShot(1760000);
				
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
  	
  	event void Timer_25.fired()
  	{
  		if (stage_25 == 1)
  		{
  			call Leds.led2Toggle();
			msg_25 = call Packet.getPayload(&packet_25, sizeof(timesync_msg_t));
			msg_25->recv_time = call LocalTime.get();
			msg_25->local_time = call LocalTime.get();
			msg_25->src = TOS_NODE_ID;
			call Send_25_1.send(AM_BROADCAST_ADDR, &packet_25, sizeof(timesync_msg_t));
			call Timer_25.startOneShot(160000);

			return;
  		}

  		if (stage_25 == 2)
  		{
  			call Leds.led1Toggle();
			rmsg_25->local_time = call LocalTime.get();//Replace with packet-level timestamping later
			call Send_25_3.send(AM_BROADCAST_ADDR, &rpacket_25, sizeof(timesync_msg_t));
			call Timer_25.startOneShot(160000);// This is a repeat timer for the second message to be sent to Node3
			
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
			call Timer_25.startOneShot(80000);//(global time 740)(560 s is worst case scenario for 1 transmission)
			
			}else	
				call Timer_12.startOneShot(80000);
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
	
	event message_t* TSReceive_25_2.receive(message_t* bufPtr, void* payload, uint8_t len)
	{

		B2p = call LocalTime.get();

		call Leds.led1Toggle();

		call Timer_25.stop();
		rcm = (timesync_msg_t*) payload;
		
		//Preparing a reply (third link of the 3Msg protocol)
		rmsg_25 = call Packet.getPayload(&rpacket_25, sizeof(timesync_msg_t));
		rmsg_25->recv_time = B2p;
		//Send Timestamping done at timer.
		rmsg_25->src = TOS_NODE_ID;

		stage_25 = 2;

		call Timer_25.startOneShot(20000);

		return bufPtr;

	}


	//Wired to BroadSend5
	event message_t* TSReceive_25_4.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		call Timer_25.stop();
		return bufPtr;
	}


	event message_t* DataReceive_52.receive(message_t* bufPtr, void* payload, uint8_t len)
	{
		data_msg_52 = (data_t*)call Packet.getPayload(&dpacket_52, sizeof(data_t));
		data_incoming_52 = (data_t*)payload;

		data_msg_52->data = (data_incoming_52->data)+2;
		data_msg_52->src = TOS_NODE_ID;

		// Data aggregation still needs to be done; only after Data_42 should we be sending.
		call Leds.led0Toggle();

		call Timer_Data_21.startOneShot(10000);
		return bufPtr;
	}

	event void Send_12_2.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}


	event void Send_12_4.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}

	event void Send_25_1.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}

	event void Send_25_3.sendDone(message_t* bufPtr, error_t error) {
		call Leds.led1Toggle();
	}

	event void Send_21_Data.sendDone(message_t* bufPtr, error_t error){
		call Leds.led1Toggle();
		call Leds.led2Toggle();
	}
}