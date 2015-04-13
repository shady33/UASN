#ifndef ChildNodes_H
#define ChildNodes_H
enum{
	AM_CHANNEL = 16,
	TIMER_PERIOD=1000
};
typedef nx_struct TimeSyncCMessage{
	nx_uint16_t nodeid;
	nx_uint16_t msgtype;
	nx_uint16_t clusterheadnumber;
	nx_uint16_t slotnumber;
	nx_uint16_t nextclusterhead;
}TimeSyncCMessage;

typedef nx_struct SendCMsg {
	nx_uint32_t nodeid;
	nx_uint32_t value;
	nx_uint32_t msgtype;
}SendCMsg;

#endif /* ChildNodes_H */
