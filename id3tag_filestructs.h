/*
 *  id3tag_filestructs.h
 *  TriTag
 *
 *  Created by Patrick Gleichmann on Wed Feb 11 2004.
 *  Copyright (c) 2004 FEEDFACE.com. All rights reserved.
 *
 *  Just the structs from "src/file.c"
 */

#ifndef __ID3TAG_FILESTRUCTS_H__
#define __ID3TAG_FILESTRUCTS_H__

struct filetag {
	struct id3_tag *tag;
	unsigned long location;
	id3_length_t length;
};

struct id3_file {
	FILE *iofile;
	enum id3_file_mode mode;
	char *path;
	
	int flags;
	
	struct id3_tag *primary;
	
	unsigned int ntags;
	struct filetag *tags;
};

#endif // !__ID3TAG_FILESTRUCTS_H__
