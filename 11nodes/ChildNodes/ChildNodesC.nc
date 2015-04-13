#include "ChildNodes.h"
#include <Timer.h>
//#include "printf.h"

module ChildNodesC{
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
}
implementation{
	message_t pkt;
	uint16_t clusternumber = 0;
	uint16_t nodenumber = 0;
	bool clusterhead = FALSE;
	uint16_t chead1 = 1;
	uint16_t chead2 = 1;
	uint32_t noofcycles = 0;
	uint16_t nexthop = 0;
	bool syncwithclusterhead = FALSE;
	int clusterheadnumber = 0;
	uint16_t syncwithnode = 0;
	uint16_t slotnumber = 0;
	bool data = FALSE;
	bool timesync = FALSE;

	void send10(uint16_t nodeid){
		//TimeSync Send here
		TimeSyncCMessage* btrpkt=(TimeSyncCMessage*)(call Packet.getPayload(&pkt, sizeof (TimeSyncCMessage)));
		btrpkt->nodeid = TOS_NODE_ID;
		btrpkt->msgtype = 10;

		if(call AMSend.send(nodeid,&pkt,sizeof(TimeSyncCMessage))==SUCCESS){
			//call Leds.led0Toggle();
		}
	}

	void send11(){
		TimeSyncCMessage* btrpkt=(TimeSyncCMessage*)(call Packet.getPayload(&pkt, sizeof (TimeSyncCMessage)));
		btrpkt->nodeid = TOS_NODE_ID;
		btrpkt->msgtype = 11;
		if(call AMSend.send(nexthop,&pkt,sizeof(TimeSyncCMessage))==SUCCESS){
			call Leds.led1Toggle();
		}
	}

	void send12(uint16_t nodeid,uint16_t var1,uint16_t slotnum){
		TimeSyncCMessage* btrpkt=(TimeSyncCMessage*)(call Packet.getPayload(&pkt, sizeof (TimeSyncCMessage)));
		btrpkt->nodeid = TOS_NODE_ID;
		btrpkt->msgtype = 12;
		btrpkt->clusterheadnumber = var1;
		btrpkt->slotnumber = slotnum;
		btrpkt->nextclusterhead = chead2;
		
		if(call AMSend.send(nodeid,&pkt,sizeof(TimeSyncCMessage))==SUCCESS){
			call Leds.led2Toggle();
		}
		syncwithclusterhead = FALSE;
	}

	event void Boot.booted(){
		call AMControl.start();
		clusternumber = TOS_NODE_ID / 10;
		nodenumber = TOS_NODE_ID % 10;
	}
	
	event void AMControl.startDone(error_t error){
		if(error == SUCCESS){
			if (TOS_NODE_ID == 1){
				call Timer0.startOneShot(1000);
				syncwithclusterhead = TRUE;
			}
		}else{
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t error){
	
	}
	
	event void Timer0.fired(){
		if (TOS_NODE_ID == 1){
			if (noofcycles == 3){
				//New ClusterHead for 1
				noofcycles = 0;
				chead1++;
				if(chead1 == 6){
					chead1 = 1;
				}
			}else{
				//Use old ClusterHead for 1
				noofcycles++;			
			}
			clusterheadnumber = 10+chead1;
			syncwithclusterhead = TRUE;
			send10(clusterheadnumber);
		}else{
			//TimeSync of Chead1 and Chead2
			syncwithnode++;
			if(syncwithnode == nodenumber){
				call Timer0.startOneShot(10);
			}else {
				if (syncwithnode == 10 && clusternumber == 1){
					syncwithclusterhead = TRUE;

					if (noofcycles == 3){
						//New ClusterHead for 1
						noofcycles = 0;
						chead2++;
						if(chead2 == 6){
							chead2 = 1;
						}
					}else{
						//Use old ClusterHead for 1
						noofcycles++;			
					}
					clusterheadnumber = (clusternumber+1)*10+chead2;
					timesync = TRUE;

					if (clusterhead == TRUE){
						call Timer0.startOneShot(250);
					}

					send10((clusternumber+1)*10+chead2);
				}else if(syncwithnode < 10 ){
					if (clusterhead == TRUE){
						call Timer0.startOneShot(250);
					}
					timesync = TRUE;
					send10(clusternumber*10+syncwithnode);
				}else{
					call Timer0.stop();
				}
			}
		}
	}

	//Data timer
	event void Timer1.fired(){
		call Leds.led0Toggle();
		if(data == TRUE){
			SendCMsg* btrpkt=(SendCMsg*)(call Packet.getPayload(&pkt, sizeof (SendCMsg)));
			btrpkt->nodeid=TOS_NODE_ID;
			btrpkt->value=15;
			if(call AMSend.send(nexthop,&pkt,sizeof(SendCMsg))==SUCCESS){
				//call Leds.led0Toggle();
				syncwithnode = 0;
				data = FALSE;
			}
		}else {
			timesync = FALSE;
			call Timer0.startOneShot(50);
		}
	}
	
	event void AMSend.sendDone(message_t *msg, error_t error){
		
	}
	
	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
			

		if(len == sizeof(TimeSyncCMessage)){
			TimeSyncCMessage* btrpkt = (TimeSyncCMessage*)payload;
			if(btrpkt->msgtype == 10){
				nexthop = btrpkt->nodeid;
				send11();
			}else if(btrpkt->msgtype == 11){
				uint8_t dummyvariable = 0;
				timesync = FALSE;
				if(syncwithclusterhead == TRUE){
					dummyvariable = clusterheadnumber;
					clusterheadnumber = 0;
				}
				if (clusterhead == TRUE){
					//call Timer0.startOneShot(50);
				}
				slotnumber++;
				send12(btrpkt->nodeid,dummyvariable,slotnumber);
			}else if(btrpkt->msgtype == 12){
				//TimeSync Third Message Complete
				data = TRUE;
				if (btrpkt->clusterheadnumber == TOS_NODE_ID){
					clusterhead = TRUE;
					call Timer0.startOneShot(1000);
					call Timer1.startOneShot(((3-clusternumber)*5000)+1000);
				}else{
					chead2 = btrpkt->nextclusterhead;
					clusterhead = FALSE;
					noofcycles = 2;
					call Timer1.startOneShot(((3-clusternumber)*3600 )+ 10 - btrpkt->slotnumber);
				}
			}
		}else{
			call Leds.led2Toggle();
			if(TOS_NODE_ID == 1){
				call Timer0.startOneShot(32000);
			}
		}
		return msg;
	}
}