/*
 * "Copyright (c) 2004-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#ifndef TIME_SYNC_COMMON_H
#define TIME_SYNC_COMMON_H

typedef nx_struct timesync_msg {
  nx_uint8_t src;
  nx_uint32_t local_time;
  nx_uint32_t recv_time;
} timesync_msg_t;

typedef nx_struct timesync_broad {
	nx_uint8_t src;
	nx_uint32_t slope;
	nx_uint32_t offset;
}timesync_broad_t;

typedef nx_struct data {
	nx_uint8_t src;
	nx_uint32_t timestamp;
	nx_uint16_t data;
	
}data_t;

enum {
  AM_TS_12_1 = 32,
  AM_TS_12_2 = 33,
  AM_TS_12_3 = 34,
  AM_TS_12_4 = 35,
  AM_TS_25_1 = 36,
  AM_TS_25_2 = 37,
  AM_TS_25_3 = 38,
  AM_TS_25_4 = 39,
  AM_TS_25_4_2 = 40,
  AM_TS_23_1 = 41,
  AM_TS_23_2 = 42,
  AM_TS_23_3 = 43,
  AM_TS_23_4 = 44,
  AM_TS_24_1 = 45,
  AM_TS_24_2 = 46,
  AM_TS_24_3 = 47,
  AM_TS_24_4 = 48,
  AM_TS_56_1 = 49,
  AM_TS_56_2 = 50,
  AM_TS_56_3 = 51,
  AM_TS_56_4 = 52,
  AM_TS_57_1 = 53,
  AM_TS_57_2 = 54,
  AM_TS_57_3 = 55,
  AM_TS_57_4 = 56,
  AM_D_75 = 64,
  AM_D_65 = 65,
  AM_D_52 = 66,
  AM_D_32 = 67,
  AM_D_42 = 68,
  AM_D_21 = 69,
  AM_D_1B = 70
  
};

#endif
