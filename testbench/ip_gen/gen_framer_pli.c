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

int fseq_sizetf()
{
    return(32);
}

int fseq_calltf()
{

	int blk_num_monitor,fin,dv1,len1,dv2,len2,dv3,len3,dv4,len4,dv5,len5,dv6,len6,state_monitor;
	int start,dvin,havereg;
	start=tf_getp(1)&1;
	dvin=tf_getp(2)&1;
	havereg=tf_getp(18)&1;

	calc_blocks_len(start,dvin,&fin,&dv1,&len1,&dv2,&len2,&dv3,&len3,&dv4,&len4,&dv5,&len5,&dv6,&len6,&state_monitor,&blk_num_monitor,havereg);

    tf_putp(3, fin);
	tf_putp(4, dv1); tf_putp(5, len1);
	tf_putp(6, dv2); tf_putp(7, len2);
	tf_putp(8, dv3); tf_putp(9, len3);
	tf_putp(10, dv4); tf_putp(11, len4);
	tf_putp(12, dv5); tf_putp(13, len5);
	tf_putp(14, dv6); tf_putp(15, len6);
	tf_putp(16, state_monitor);
	tf_putp(17, blk_num_monitor);


    return(0);
}


int fseq_checktf()
{
    bool err = FALSE;
    if (tf_nump() != 18) {
        tf_error("For work this function I need 14 arguments!!!!.\n");
        err = TRUE;
    }
    if (tf_typep(1) == tf_nullparam) {
        tf_error("Memory can't a NULL argument.\n");
        err = TRUE;
    }
    if (tf_sizep(1) > 32) {
        tf_error("I have made block only for values not more integer=32bit.\n");
        err = TRUE;
    }
    if (err) {
        tf_message(ERR_ERROR, "", "", "");
    }
    return(0);
}

#define BLOCK_LEN	(188-9)
int state=0;
unsigned int blocks_len[60];
unsigned int blocks_dv[60];
unsigned int all_len=0;
unsigned int cur_blk_num=0;

int calc_blocks_len(int start,int dvin,int *fin,int *dv1,int *len1,int *dv2,int *len2,int *dv3,int *len3,int *dv4,int *len4,int *dv5,int *len5,int *dv6,int *len6, int *state_monitor, int *blk_num_monitor, int havereg)
{
int z;

*state_monitor=state;
*blk_num_monitor=cur_blk_num;
				*dv1=blocks_dv[0]; *dv2=blocks_dv[1]; *dv3=blocks_dv[2]; *dv4=blocks_dv[3];
				*dv5=blocks_dv[4]; *dv6=blocks_dv[5];
				*len1=blocks_len[0]; *len2=blocks_len[1]; *len3=blocks_len[2]; *len4=blocks_len[3]; 
				*len5=blocks_len[4]; *len6=blocks_len[5]; 

	switch (state)
	{
	case 0: 
		all_len=0;
		cur_blk_num=0;
		for (z=0;z<6;z++)
			{
			 blocks_len[z]=0;
			 blocks_dv[z]=0;
			}

		if (start==1) 
		{
			state=1;
			if (havereg==1)  blocks_len[0]=1;
		}


				*dv1=blocks_dv[0]; *dv2=blocks_dv[1]; *dv3=blocks_dv[2]; *dv4=blocks_dv[3];
				*dv5=blocks_dv[4]; *dv6=blocks_dv[5];
				*len1=blocks_len[0]; *len2=blocks_len[1]; *len3=blocks_len[2]; *len4=blocks_len[3]; 
				*len5=blocks_len[4]; *len6=blocks_len[5]; 


		*fin=0;
		break;

	case 1:
		blocks_dv[cur_blk_num]=dvin;
		blocks_len[cur_blk_num]=1;
				*len1=blocks_len[0]; *len2=blocks_len[1]; *len3=blocks_len[2]; *len4=blocks_len[3]; 
				*len5=blocks_len[4]; *len6=blocks_len[5]; 

		all_len++;
		*fin=0;
		if (dvin==0) state=2;
		else state=3;
		break;

	case 2: //# count dv='0' 		

		if (dvin==0)
			{	
				blocks_len[cur_blk_num]++;
				if (blocks_len[cur_blk_num]>=64)
				{
					cur_blk_num++;			
					if (cur_blk_num<6)
					{			
						blocks_dv[cur_blk_num]=0;
						blocks_len[cur_blk_num]=1;
					}
				}
			}
		else
			{
			 cur_blk_num++;
			 if (cur_blk_num<6)
			 {			
			 	blocks_dv[cur_blk_num]=1;
			 	blocks_len[cur_blk_num]=1;
			 }
			 state=3;
			}
				*len1=blocks_len[0]; *len2=blocks_len[1]; *len3=blocks_len[2]; *len4=blocks_len[3]; 
				*len5=blocks_len[4]; *len6=blocks_len[5]; 

		all_len++;
		if ((all_len>=BLOCK_LEN) || (cur_blk_num>=6)) 
			{
				*dv1=blocks_dv[0]; *dv2=blocks_dv[1]; *dv3=blocks_dv[2]; *dv4=blocks_dv[3];
				*dv5=blocks_dv[4]; *dv6=blocks_dv[5];
				*len1=blocks_len[0]; *len2=blocks_len[1]; *len3=blocks_len[2]; *len4=blocks_len[3]; 
				*len5=blocks_len[4]; *len6=blocks_len[5]; 
				*fin=1;
				state=0;
			} else *fin=0;
		break;
	case 3: //# count dv='1'

		if (dvin==1)
			{	
				blocks_len[cur_blk_num]++;
				if (blocks_len[cur_blk_num]>=64)
				{
					cur_blk_num++;
					if (cur_blk_num<6)
					{			
						blocks_dv[cur_blk_num]=1;
						blocks_len[cur_blk_num]=1;
					}
				}
			}
		else
			{
			 cur_blk_num++;
			 if (cur_blk_num<6)
			 {			
			 	blocks_dv[cur_blk_num]=0;
			 	blocks_len[cur_blk_num]=1;
			 }
			 state=2;
			}
				*len1=blocks_len[0]; *len2=blocks_len[1]; *len3=blocks_len[2]; *len4=blocks_len[3]; 
				*len5=blocks_len[4]; *len6=blocks_len[5]; 

		all_len++;
		if ((all_len>=BLOCK_LEN) || (cur_blk_num>=6)) 
			{
				*dv1=blocks_dv[0]; *dv2=blocks_dv[1]; *dv3=blocks_dv[2]; *dv4=blocks_dv[3];
				*dv5=blocks_dv[4]; *dv6=blocks_dv[5];
				*len1=blocks_len[0]; *len2=blocks_len[1]; *len3=blocks_len[2]; *len4=blocks_len[3]; 
				*len5=blocks_len[4]; *len6=blocks_len[5]; 
				*fin=1;
				state=0;
			} else *fin=0;
		break;
		default: state=0; break;	
	} //#switch
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
     "$calc_lens"       // "$tfname" system task/function name
    },
    {0}                 // final entry must be 0
};
