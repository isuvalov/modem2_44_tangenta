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

#define PRINT_ENA

int fseq_sizetf()
{
    return(8);
}

int fseq_calltf()
{
	unsigned char dv;
	unsigned char data;
	int ret;
	dv=tf_getp(1);
	data=tf_getp(2);
	ret=test_ipgen(dv,data);
	tf_putp(0, ret );
    return(0);
}


int fseq_checktf()
{
    bool err = FALSE;
    if (tf_nump() != 2) {
        tf_error("For work this function I need 2 arguments!!!!.\n");
        err = TRUE;
    }
    if (tf_typep(1) == tf_nullparam) {
        tf_error("Memory can't a NULL argument.\n");
        err = TRUE;
    }
    if (tf_sizep(1) > 16) {
        tf_error("I have made tester only for values not more integer=8bit.\n");
        err = TRUE;
    }
    if (err) {
        tf_message(ERR_ERROR, "", "", "");
    }
    return(0);
}

unsigned int timecnt=0;
int frame_cnt=0;
int state=0;
unsigned char local_dv=0;
unsigned char data_cnt=1;
int local_dv_cnt=0;
unsigned char dvframe_counter=1;


int test_ipgen(int dv,int data2)
{
unsigned char data;
data=data2&0xFF;

	switch (state)
	{
		case 0:
			if (dv==1) 
			{
				dvframe_counter=data;
				state=1;
			}
			break;
		case 1:
			if (dv==1)
			{
				data_cnt=data;
				state=3;
			} else
			{
				state=0;
				#ifdef PRINT_ENA
				io_printf("Too short dv length with frame number %2.x\n",dvframe_counter);
				#endif
				return 1;
			}
			break;
		case 2:
			if (dv==1)
			{
				dvframe_counter++;
				if (dvframe_counter!=data)
				{
					#ifdef PRINT_ENA
					io_printf("Error frame number %2.x!=%2.x\n",data,dvframe_counter);	
					#endif
					dvframe_counter=data;
					state=3;
					return 1;
				}
				state=3;
				
			}  			break;
		case 3:
			if (dv==1)
			{
				data_cnt++;
				if (data_cnt!=data)
				{
					#ifdef PRINT_ENA
					io_printf("Error data %2.x!=%2.x in frame %x\n",data,data_cnt,dvframe_counter);	
					#endif
					data_cnt=data;
					return 1;
				}
			} else state=2;
			break;
		default: break;
	}   // case

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
     "$ipgen_test"       // "$tfname" system task/function name
    },
    {0}                 // final entry must be 0
};
