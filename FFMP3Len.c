RCS_ID("$Id: FFMP3Len.c 243 2004-08-12 18:14:36Z ravemax $")

#include "FFMP3Len.h"
#include <stdio.h>
#import <string.h>
#include "mp3tech.h"

int mp3len(const char* fname) {
	FILE*	fp;	
	mp3info	mp3;
	
	fp = fopen(fname, "r");
	if (fp == NULL)
		return 0;
	
	memset(&mp3, 0, sizeof(mp3info));
	mp3.filename = (char*)fname;
	mp3.file = fp;
	get_mp3_info(&mp3, SCAN_QUICK, 1); // fullscan_vbr = 1
	
	fclose(fp);
	
	return mp3.seconds;
}
