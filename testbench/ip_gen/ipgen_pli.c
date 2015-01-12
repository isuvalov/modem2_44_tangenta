//
// Copyright 1991-2010 Mentor Graphics Corporation
//
// All Rights Reserved.
//
// THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION WHICH IS THE
// PROPERTY OF MENTOR GRAPHICS CORPORATION OR ITS LICENSORS AND IS SUBJECT TO
// LICENSE TERMS.
//
// Simple Verilog PLI Example - C function to compute fibonacci seq.
//
#include "veriuser.h"
#include "acc_user.h"
#include <stdlib.h>
#include <math.h>

//const int framesizes[8]={885,886,887,888,889,890,891,892};
//const int framesizes[8]={64,64,64,64,64,64,64,64};
const int framesizes[8]={1518,1518,1518,1518,1518,1518,1518,1518};
//const int framesizes[8]={200,200,200,200,200,200,200,200};
int framesize_p=0;


int fseq_sizetf()
{
    return(8);
}

int fseq_calltf()
{

	unsigned char dv,data;
	mk_ipgen(tf_getp(1),&dv,&data);
    
	tf_putp(2, dv);
	tf_putp(3, data);
    return(0);
}


int fseq_checktf()
{
    bool err = FALSE;
    if (tf_nump() != 3) {
        tf_error("For work this function I need 3 arguments!!!!.\n");
        err = TRUE;
    }
    if (tf_typep(1) == tf_nullparam) {
        tf_error("Memory can't a NULL argument.\n");
        err = TRUE;
    }
    if (tf_sizep(1) > 16) {
        tf_error("I have made memory only for values not more integer=16bit.\n");
        err = TRUE;
    }
    if (err) {
        tf_message(ERR_ERROR, "", "", "");
    }
    return(0);
}

int mrand()
{
 //return 1000;
 return rand();
}

unsigned int timecnt=0;
int frame_cnt=0;
int state=-2;
unsigned char local_dv=0;
unsigned char data_cnt=1;
int local_dv_cnt=0;
int dvframe_counter=1;
//#define MINFRAME_LEN	1300.0
//#define PAUSE_LEN	12.0
//#define FRAME_LEN	1518.0
#define MINFRAME_LEN	1000.0
#define PAUSE_LEN	10.0
#define FRAME_LEN	1500.0


int mk_ipgen(int rd,int *dv, unsigned char *data)
{
	switch (state)
	{
	case -2: 
			srand(1000);
			state=-1;
			*dv=0;
			*data=0;

			break;
	case -1:		
			local_dv=local_dv_cnt&1; 
			local_dv_cnt++;
			if (local_dv==1)
				{
					*dv=1;
					dvframe_counter++;
					*data=dvframe_counter;
					state=0;
				} else
				{
					*dv=0;
					*data=0;
					frame_cnt=1+(PAUSE_LEN*mrand()/RAND_MAX);
					frame_cnt=(PAUSE_LEN);
					*dv=0;
					*data=0;
					state=1;
				}
			break;
	case 0: 
			if (local_dv==1)
			{
				frame_cnt=framesizes[framesize_p];
				framesize_p=framesize_p++;
				framesize_p=framesize_p%8;
				frame_cnt=MINFRAME_LEN+(FRAME_LEN*mrand()/RAND_MAX);
				frame_cnt=FRAME_LEN;
				*dv=1;
				*data=data_cnt;//dvframe_counter;
				data_cnt++;
				//io_printf("Go to state=1 with dv=1 and cnt=%i\n",frame_cnt);
			} else
			{
				frame_cnt=1+(PAUSE_LEN*mrand()/RAND_MAX);
				frame_cnt=(PAUSE_LEN);

				*dv=0;
				*data=0;
				//io_printf("Go to state=1 with dv=0 and cnt=%i\n",frame_cnt);
			}
			state=1;
			break;
	case 1: 
			if (local_dv==1)
			{
				*dv=1;
				*data=data_cnt;//dvframe_counter;
				data_cnt++;
			} else
			{
				*dv=0;
				*data=0;
			}
			frame_cnt--;
			if (frame_cnt==0) state=-1;
				//io_printf("cnt=%i\n",frame_cnt);
			break;
	default: break;
	}


 return 0;
}


s_tfcell veriusertfs[] =
{
    {userfunction,      // type of PLI routine - usertask or userfunction
     0,                 // user_data value
     fseq_checktf,      // checktf() routine
     fseq_sizetf,       // sizetf() routine
     fseq_calltf,       // calltf() routine
     0,                 // misctf() routine
     "$ipgen"       // "$tfname" system task/function name
    },
    {0}                 // final entry must be 0
};
