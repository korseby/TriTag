RCS_ID("$Id: FFData.m 264 2004-08-20 14:22:11Z ravemax $")

#import "FFData.h"
#import <id3tag.h>
#import "id3tag_filestructs.h"

#import <string.h>
//#import <id3.h>
//#import "id3lib_enc_wrapper.h"

#import "FFPlaceholders.h"
#import "FFFilenameToTag.h"
#import "FFTagToFilename.h"
#import "FFController.h"
#import "FFV1Genres.h"
//#import "FFFreeDB.h"
#import "FFMP3Len.h"

@implementation FFData

// Consts
static const unsigned PaddingAssumedBlockSize = 4096;
static const unsigned PaddingMinPadSize = 512;

// The special idents
		NSString* FilePathIdent		= @"Filepath"; // Internal use
static NSString* FilenameIdent		= @"Filename";
static NSString* CompilationIdent	= @"Compilation"; // Internal use
static NSString* CommentIdent		= @"Comment";   // Internal use
static NSString* DataOfsIdent		= @"data_ofs"; // Internal use
static NSString* DataSizeIdent		= @"data_size"; // Internal use
static NSString* HasV1TagIdent		= @"has_v1_tag"; // Internal use
static NSString* V1TagOfsIdent		= @"v1_tag_ofs"; // Internal use
static NSString* ArrayIndexIdent	= @"array_index"; // Internal use
static NSString* RemovedWhileSortingIdent = @"removed_sort"; // Internal use
static NSString* CommentTextEncIdent	= @"cmt_text_enc"; // Internal use
static NSString* CommentLanguageIdent	= @"cmt_lang"; // Internal use
static NSString* CommentShortTextIdent	= @"cmt_short_txt"; // Internal use
static NSString* CommentFullTextIdent	= @"cmt_full_txt"; // Internal use

static NSString* FileExtension		= @"mp3";
static NSString* Unknown			= @"_Unknown";
static NSString* Compilations		= @"_Compilations";

// No way to convert a defined string into a static NSString ?
static NSString* FrameTitleIdent 	= @"TIT2"; // ID3_FRAME_TITLE
static NSString* FrameArtistIdent 	= @"TPE1"; // ID3_FRAME_ARTIST
static NSString* FrameAlbumIdent 	= @"TALB"; // ID3_FRAME_ALBUM
static NSString* FrameTrackIdent 	= @"TRCK"; // ID3_FRAME_TRACK
static NSString* FrameYearIdent		= @"TDRC"; // ID3_FRAME_YEAR
static NSString* FrameGenreIdent	= @"TCON"; // ID3_FRAME_GENRE
static NSString* FrameCommentIdent  = @"COMM"; // ID3_FRAME_COMMENT

// Vars
static NSColor*			m_filenameColor;
static NSFileManager*	m_fileManager;
static NSDictionary*	m_emptyIdentRow;
static NSDictionary*	m_identToFrame;

/*
 *	Init & destroy
 */
+ (void)initialize
{
	m_filenameColor = [[NSColor secondarySelectedControlColor] retain];
	m_fileManager = [[NSFileManager defaultManager] retain];

	m_identToFrame = [[NSDictionary dictionaryWithObjectsAndKeys:
		FrameTitleIdent,	TrackTitleIdent,
		FrameArtistIdent,   ArtistIdent,
		FrameAlbumIdent,	AlbumIdent,
		FrameTrackIdent,	TrackNumberIdent,
		FrameYearIdent,		YearIdent,
		FrameGenreIdent,	GenreIdent,
		FrameCommentIdent,  CommentIdent,
		nil] retain];

	m_emptyIdentRow = [[NSDictionary dictionaryWithObjectsAndKeys:
		@"", ArtistIdent,
		@"", AlbumIdent,
		@"", TrackNumberIdent,
		@"", TrackTitleIdent,
		@"", YearIdent,
		@"", GenreIdent,
//		nil, CommentIdent, // Not necessary and also not possible because obj=nil
		nil] retain];
}

- (id)init
{
	if (self = [super init]) {
		m_tableArray = [[NSMutableArray alloc] init];	
	}
	return self;
}

- (void)dealloc
{	
	[m_tableArray release];
	[super dealloc];
}

/*
 *	Delegate
 */
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)col row:(int)rowIndex
{
	if ([[col identifier] isEqualTo:FilenameIdent]) {
		[cell setBackgroundColor:m_filenameColor];
		[cell setDrawsBackground:TRUE];
	}
}

/*
 *	Data source
 */
- (int)numberOfRowsInTableView:(NSTableView*)tv
{
	return [m_tableArray count];
}

- (id)tableView:(NSTableView*)tv objectValueForTableColumn:(NSTableColumn*)col row:(int)rowIndex
{
	return [[m_tableArray objectAtIndex:rowIndex] objectForKey:[col identifier]];
}

- (void)tableView:(NSTableView*)tv setObjectValue:(id)value forTableColumn:col row:(int)rowIndex {
	[[m_tableArray objectAtIndex:rowIndex] setObject:value forKey:[col identifier]];
}

/*
 *	Adding and removing files (= paths)
 */
- (BOOL)_isfilePathAlreadyRegistered:(NSString*)fpath
{
	NSEnumerator*	en;
	NSDictionary*	dict;
	
	en = [m_tableArray objectEnumerator];
	while (dict = [en nextObject]) {
		if ([[dict objectForKey:FilePathIdent] isEqualTo:fpath])
			return TRUE;
	}
	
	return FALSE;
}

- (void)_readComment:(NSMutableDictionary*)dict field:(union id3_field*)afield {
	id3_ucs4_t*				ustr;
	NSMutableDictionary*	cd;

	// Create comment dict
	cd = [dict objectForKey:CommentIdent];
	if (cd == nil) {
		cd = [[NSMutableDictionary alloc] initWithCapacity:1];
		[dict setObject:cd forKey:CommentIdent];
	}
	
	#define UCS4_TO_NSTRING(METHOD, IDENT)	\
		ustr	= (id3_ucs4_t*)id3_ucs4_utf16duplicate(METHOD); \
		[cd setObject:[NSString stringWithFormat:@"%S", ustr] forKey:IDENT]; \
		free(ustr);
	
	switch (id3_field_type(afield)) {
		case ID3_FIELD_TYPE_TEXTENCODING :
			[cd setObject:[NSNumber numberWithLong:afield->number.value] forKey:CommentTextEncIdent];  // no method ?
			break;
		case ID3_FIELD_TYPE_LANGUAGE :
			[cd setObject:[NSString stringWithFormat:@"%c%c%c", 
				afield->immediate.value[0], afield->immediate.value[1], afield->immediate.value[2]] 
				   forKey:CommentLanguageIdent]; // No method ?
			break;
		case ID3_FIELD_TYPE_STRING :
			UCS4_TO_NSTRING(id3_field_getstring(afield), CommentShortTextIdent)
			break;
		case ID3_FIELD_TYPE_STRINGFULL :
			UCS4_TO_NSTRING(id3_field_getfullstring(afield), CommentFullTextIdent)
			break;
		default :
			// Unsupported type
			return;
	}
}

- (NSDictionary*)_createFramesDictForTag:(struct id3_tag*)itag
{
	NSMutableDictionary*	dict;
	unsigned				i, j;
	struct	id3_frame*		aframe;
	union	id3_field*		afield;
	unsigned				nstr;
	id3_utf16_t*			ustr;
	NSString*				ftxt;
	BOOL					isComment;

	dict = [[NSMutableDictionary dictionary] retain];
	for (i = 0; i < itag->nframes; i++) {
		aframe		= itag->frames[i];
		isComment   = (BOOL)!strncmp(aframe->id, ID3_FRAME_COMMENT, 4);
		
		for (j = 0; j < aframe->nfields; j++) {
			afield = id3_frame_field(aframe, j);

			// All fields of a comment are stored
			if (isComment)
				[self _readComment:dict field:afield];

			// Only string for the rest of the frames
			else {
				nstr = id3_field_getnstrings(afield);
				if (nstr > 0) {
					ustr	= id3_ucs4_utf16duplicate(id3_field_getstrings(afield, 0));
					ftxt	= [NSString stringWithFormat:@"%S", ustr];
				
					// Special handling for genres
					if (!strcmp(aframe->id, ID3_FRAME_GENRE)) {
						if (([ftxt length] == 1) || ([ftxt length] == 2))
							ftxt = v1GenreToString([ftxt intValue]);
					}

					// Store it
					if (ftxt != nil)
						[dict setObject:ftxt forKey:[NSString stringWithCString:aframe->id]];
					free(ustr);
				}
			}
		}
	}
	
	////
//	NSLog(@"%@", dict);
	
	return dict;
}

- (NSString*)_emptyIfNilString:(NSString*)str
{
	if (str == nil)
		return @"";
	return str;
}

- (BOOL)_addFile:(NSString*)fpath
{
	NSFileHandle*		fh;
	NSString*			fname;
	struct	id3_file*	ifile;
	struct	id3_tag*	itag;
	NSDictionary*		tagDict;
	unsigned			i, firstOfs, lastOfs, fileSize;
	BOOL				hasV1;
	
	fname = [fpath lastPathComponent];
	if (![[[fname pathExtension] lowercaseString] isEqualToString:FileExtension])
		return TRUE;

	// Read tag
	fh = [[NSFileHandle fileHandleForReadingAtPath:fpath] retain];
	if (fh == nil) {
		if (NSRunAlertPanel(@"Open error", @"Failed to open\n'%@'",
							@"Continue", @"Stop adding files", nil, fpath) == NSAlertDefaultReturn)
			return TRUE;
		return FALSE;
	}
	ifile = id3_file_fdopen([fh fileDescriptor], ID3_FILE_MODE_READONLY);
	if (ifile == NULL) {
		NSLog(@"id3_file_open failed");
		return TRUE;
	}
	itag = id3_file_tag(ifile);
	if (itag == NULL) {
		NSLog(@"id3_file_tag failed");
		return TRUE;
	}
	tagDict = [self _createFramesDictForTag:itag];
	
	// Determine the data size & ofs
	firstOfs	= 0;
	fileSize	= (unsigned)[fh seekToEndOfFile];
	lastOfs		= fileSize;
	
//	NSLog(@"lastOfs = %lu", lastOfs);
	for (i = 0; i < ifile->ntags; i++) {
		if (ifile->tags[i].location == 0)
			firstOfs = ifile->tags[i].length;
		else if (ifile->tags[i].location < lastOfs)
			lastOfs = ifile->tags[i].location;
	}
	hasV1 = (BOOL)(lastOfs < fileSize);

//	NSLog(@"datasize: ofs=%lu, size=%lu, lastOfs=%lu", firstOfs, lastOfs-firstOfs, lastOfs);
	
	// Free the tag memory
	id3_tag_delete(itag);
	id3_file_close(ifile);

	// Add
	NSMutableDictionary* fdict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		fpath, FilePathIdent,
		fname, FilenameIdent,
		[self _emptyIfNilString:[tagDict objectForKey:FrameArtistIdent]], ArtistIdent,
		[self _emptyIfNilString:[tagDict objectForKey:FrameAlbumIdent]], AlbumIdent,
		[self _emptyIfNilString:[tagDict objectForKey:FrameTrackIdent]], TrackNumberIdent,
		[self _emptyIfNilString:[tagDict objectForKey:FrameTitleIdent]], TrackTitleIdent,
		[self _emptyIfNilString:[tagDict objectForKey:FrameYearIdent]], YearIdent,
		[self _emptyIfNilString:[tagDict objectForKey:FrameGenreIdent]], GenreIdent,
		[NSNumber numberWithBool:FALSE], CompilationIdent,
		[NSNumber numberWithUnsignedInt:firstOfs], DataOfsIdent,
		[NSNumber numberWithUnsignedInt:(lastOfs - firstOfs)], DataSizeIdent,
		[NSNumber numberWithBool:hasV1], HasV1TagIdent,
		[NSNumber numberWithUnsignedInt:lastOfs], V1TagOfsIdent,
		nil];
	
	if ([tagDict objectForKey:CommentIdent] != nil)
		[fdict setObject:[tagDict objectForKey:CommentIdent] forKey:CommentIdent];
	[m_tableArray addObject:fdict];
	
//	NSLog(@"last = %@", [m_tableArray lastObject]);
	
	return TRUE;
}

- (NSArray*)_filepathsForDirectory:(NSString*)dir
{
	NSArray*		nfWOPath;
	NSMutableArray*	nfWithPath;
	NSEnumerator*	en;
	NSString*		name;
			
	nfWOPath = [m_fileManager directoryContentsAtPath:dir];
	nfWithPath = [NSMutableArray arrayWithCapacity:[nfWOPath count]];
			
	en = [nfWOPath objectEnumerator];
	while (name = [en nextObject]) {
		if ([name characterAtIndex:0] != '.')
			[nfWithPath addObject:[dir stringByAppendingFormat:@"/%@", name]];
	}
	return nfWithPath;
}

- (void)addFiles:(NSArray*)files
{
	NSEnumerator*	en;
	NSString*		fpath;
	BOOL			isDir;
	
	en = [[files sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
	while (fpath = [en nextObject]) {
		if ([m_fileManager fileExistsAtPath:fpath isDirectory:&isDir] && isDir) {// dir 
			[self addFiles:[self _filepathsForDirectory:fpath]];

		} else if (![self _isfilePathAlreadyRegistered:fpath]) // file
			if (![self _addFile:fpath])
				break;
	}
}

- (void)removeAllFiles
{
	[m_tableArray removeAllObjects];
}

- (unsigned)numOfRows
{
	return [m_tableArray count];
}

- (NSString*)stringForRow:(unsigned)row andIdent:(NSString*)ident;
{
	return [[m_tableArray objectAtIndex:row] objectForKey:ident];
}

- (void)setStringForRow:(unsigned)row andIdent:(NSString*)ident toString:(NSString*)tostr {
	[[m_tableArray objectAtIndex:row] setObject:tostr forKey:ident];
}

- (BOOL)rowIsInCompilation:(unsigned)row
{
	return [[[m_tableArray objectAtIndex:row] objectForKey:CompilationIdent] boolValue];
}

- (void)setIsCompilationForRow:(unsigned)row value:(BOOL)iscomp
{
	[[m_tableArray objectAtIndex:row] setObject:[NSNumber numberWithBool:iscomp] forKey:CompilationIdent];
}

/*
 *	Update table data or change tags / filenames
 */
- (BOOL)_createDirectoryRecursive:(NSString*)dir
{
	if (![m_fileManager fileExistsAtPath:dir]) {
		if (![self _createDirectoryRecursive:[dir stringByDeletingLastPathComponent]])
			return FALSE;
		
		return [m_fileManager createDirectoryAtPath:dir attributes:nil];
	}
	return TRUE;
}

- (BOOL)_moveFileFrom:(NSString*)oldPath to:(NSString*)newPath
{
	unsigned idx = 1;
	
	if ([oldPath isEqualTo:newPath])
		return TRUE;
	
	while ([m_fileManager fileExistsAtPath:newPath]) {
		newPath = [NSString stringWithFormat:@"%@-%u.%@", [newPath stringByDeletingPathExtension], idx, FileExtension];
		
		idx++;
	}
	
	if (![m_fileManager movePath:oldPath toPath:newPath handler:nil]) {
		NSBeginAlertSheet(@"File problems", @"Skip file", nil, nil,
						  [NSApp mainWindow], self, nil, nil, nil,
						  @"Failed to move '%@' to '%@'", oldPath, newPath);
		return FALSE;
	}

//	NSLog(@"mv %@ -> %@", oldPath, newPath);

	return TRUE;
}

- (NSString*)_outputDirPanel
{
	NSOpenPanel*	dirPanel;

	dirPanel = [NSOpenPanel openPanel];
	[dirPanel setCanChooseFiles:FALSE];
	[dirPanel setCanChooseDirectories:TRUE];
	[dirPanel setTitle:@"Select the target directory"];
	[dirPanel runModalForDirectory:NSHomeDirectory() file:nil types:nil];

	return [[dirPanel filenames] objectAtIndex:0];
}


- (void)_InsertDefaultValuesIntoDictionary:(NSMutableDictionary*)dict withOpts:(id)optObj
{
	if ([[optObj defaultArtist] length] > 0)
		if ([optObj forceDefaultValues] || ([(NSString*)[dict objectForKey:ArtistIdent] length] == 0))		
		[dict setObject:[optObj defaultArtist] forKey:ArtistIdent];

	if ([[optObj defaultAlbum] length] > 0)
		if ([optObj forceDefaultValues] || ([(NSString*)[dict objectForKey:AlbumIdent] length] == 0))
			[dict setObject:[optObj defaultAlbum] forKey:AlbumIdent];

	if ([[optObj defaultYear] length] > 0) 
		if ([optObj forceDefaultValues] || ([(NSString*)[dict objectForKey:YearIdent] length] == 0))
			[dict setObject:[optObj defaultYear] forKey:YearIdent];
	
	if ([[optObj defaultGenre] length] > 0) 
		if ([optObj forceDefaultValues] || ([(NSString*)[dict objectForKey:GenreIdent] length] == 0))
			[dict setObject:[optObj defaultGenre] forKey:GenreIdent];
}

- (NSMutableDictionary*)_createAlbumDictWithOpts:(id)optObj
{
	NSMutableDictionary*	row, *albumDict;
	unsigned				i;
	NSString*				albumTitle;
	NSMutableArray*			sa;
	
	albumDict = [NSMutableDictionary dictionary];
	for (i = 0; i < [m_tableArray count]; i++) {
		// Join with default values
		row = [NSMutableDictionary dictionaryWithDictionary:[m_tableArray objectAtIndex:i]];
		[self _InsertDefaultValuesIntoDictionary:row withOpts:optObj];
		
		// Store the index
		[row setObject:[NSNumber numberWithUnsignedInt:i] forKey:ArrayIndexIdent];
		
		// Get the album title
		albumTitle = [row objectForKey:AlbumIdent];
		if ([albumTitle length] == 0)
			albumTitle = Unknown;
		
		// Create the key=album, value="row" dict
		sa = [albumDict objectForKey:albumTitle];
		if (sa == nil) {
			sa = [NSMutableArray array];
			[albumDict setObject:sa forKey:albumTitle];
		}
		
		[sa addObject:row];
	}
	return [albumDict retain];
}

- (BOOL)_isCompilation:(NSArray*)tracks
{
	if ([tracks count] >= 2) {
		unsigned i;
		for (i = 1; i < [tracks count]; i++) {
			if (![[[tracks objectAtIndex:i] objectForKey:ArtistIdent] isEqualTo:[[tracks objectAtIndex:i-1] objectForKey:ArtistIdent]])
					return TRUE;				
		}
	}
		
	return FALSE;
}

- (void)allTagsToFolderSortedFilenamesForPattern:(NSString*)patStr withOpts:(id)optObj
{
	FFTagToFilename*		ttf;
	NSMutableDictionary*	albumDict, *tarow;
	NSEnumerator*			en;
	NSDictionary*			row;
	NSString*				albumTitle;
	NSMutableArray*			sa;
	NSString*				outDir;
	
	// Get target dir from the user
	outDir = [optObj outDirectory];
	if (outDir == nil)
		outDir = [self _outputDirPanel];

	// Create album dictionary (key = album title)
	albumDict = [self _createAlbumDictWithOpts:optObj];
	
	// Handle each album
	ttf = [[FFTagToFilename alloc] initWithPattern:patStr andOpts:optObj];
	
	en = [albumDict keyEnumerator];
	while (albumTitle = [en nextObject]) {
		NSString*	newODir, *prevODir = nil, *newFname, *oldFPath, *newFPath;
		BOOL		noAlbumTitle;
		unsigned 	i;

		sa  = [albumDict objectForKey:albumTitle];

		// Outpath
		if (![albumTitle isEqualTo:Unknown]) {
			noAlbumTitle = FALSE;
		
			if ([self _isCompilation:sa])
				newODir = [outDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", [FFTagToFilename replaceInvalidCharacters:Compilations], [FFTagToFilename replaceInvalidCharacters:albumTitle]]];
			else {
				NSString* artist = [[sa objectAtIndex:0] objectForKey:ArtistIdent];
			
				newODir = [outDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", [FFTagToFilename replaceInvalidCharacters:artist], [FFTagToFilename replaceInvalidCharacters:albumTitle]]];
			}
			
			if (![self _createDirectoryRecursive:newODir]) {
				NSBeginAlertSheet(@"Access permissions", @"Skip this album", nil, nil,
								  [NSApp mainWindow], self, nil, nil, nil,
								  @"Failed to create the directory '%@'", newODir);
				continue;
			}
//			NSLog(@"directory: %@", newODir);
		} else
			noAlbumTitle = TRUE;
		
		// All files
		for (i = 0; i < [sa count]; i++) {
			row = [sa objectAtIndex:i];
			newFname = [ttf filenameFromTag:row];
			
			if (newFname != nil) {
				oldFPath = [row objectForKey:FilePathIdent];
				
				if (noAlbumTitle) {
					NSString* artist = [row objectForKey:ArtistIdent];
					
					if ([artist length] == 0)
						newODir = [outDir stringByAppendingPathComponent:Unknown];
					else
						newODir = [outDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", [FFTagToFilename replaceInvalidCharacters:[row objectForKey:ArtistIdent]], Unknown]];

					if ((prevODir == nil) || ![newODir isEqualTo:prevODir]) {
						if (![self _createDirectoryRecursive:newODir]) {
							continue;
						}
					}
					prevODir = newODir; // retain ?
				}
				
				newFPath = [newODir stringByAppendingPathComponent:[newFname stringByAppendingPathExtension:FileExtension]];

				tarow = [m_tableArray objectAtIndex:[(NSNumber*)[row objectForKey:ArrayIndexIdent] intValue]];
				if ([self _moveFileFrom:oldFPath to:newFPath])
//					[m_tableArray removeObjectAtIndex:[(NSNumber*)[row objectForKey:ArrayIndexIdent] unsignedIntValue]];
					[tarow setObject:[NSNumber numberWithBool:TRUE] forKey:RemovedWhileSortingIdent];
				else
					[tarow setObject:[NSNumber numberWithBool:FALSE] forKey:RemovedWhileSortingIdent];	
			}
		}
	}
	[ttf release];
	
	// Remove successfully moved files from filetable
	int	idx = [m_tableArray count]-1;
	while (idx >= 0) {
		if ([[[m_tableArray objectAtIndex:idx] objectForKey:RemovedWhileSortingIdent] boolValue])
			[m_tableArray removeObjectAtIndex:idx];
		idx--;
	}
}

- (BOOL)_renameFileAtIndex:(unsigned)index toFilename:(NSString*)fname withOpt:(id)optObj
{
	NSString* oldPath, *newPath;

	oldPath = [[m_tableArray objectAtIndex:index] objectForKey:FilePathIdent];
	newPath = [optObj outDirectory];
	if (newPath == nil)
		newPath = [oldPath stringByDeletingLastPathComponent];
	else
		[self _createDirectoryRecursive:newPath];
	
	newPath = [newPath stringByAppendingPathComponent:fname];
	return [self _moveFileFrom:oldPath to:newPath];
}

- (void)allTagsToFilenamesForPattern:(NSString*)patStr withOpts:(id)optObj shouldApply:(BOOL)apply
{
	FFTagToFilename*		ttf;
	unsigned				i;
	NSMutableDictionary*	ctag;
	NSString*				newFname;
	BOOL					entryWasRemoved;
	
	ttf = [[FFTagToFilename alloc] initWithPattern:patStr andOpts:optObj];
	if (ttf == nil)
		return;
	
	i = 0;
	while (i < [m_tableArray count]) {
		entryWasRemoved = FALSE;

		// Merge with defaults
		ctag = [NSMutableDictionary dictionaryWithDictionary:[m_tableArray objectAtIndex:i]];
		[self _InsertDefaultValuesIntoDictionary:ctag withOpts:optObj];		
		newFname = [ttf filenameFromTag:ctag];
		
		// Show or apply
		if (newFname != nil) {
			newFname = [newFname stringByAppendingPathExtension:FileExtension];
			if (apply) {
//				NSLog(@"newfilename : %@", newFname);
				if ([self _renameFileAtIndex:i toFilename:newFname withOpt:optObj]) {
					[m_tableArray removeObjectAtIndex:i];
					entryWasRemoved = TRUE;
				}
				
			} else
				[[m_tableArray objectAtIndex:i] setObject:newFname forKey:FilenameIdent];
		}
		if (!entryWasRemoved)
			i++;
	}
	[ttf release];
}

/*
 Unused code !
 The ID3 lib from id3lib.org ... has problems with unicode 
 */
/*
- (void)addFrameToTag:(ID3Tag*)tag withID:(ID3_FrameID)frameID usingText:(NSString*)str
{
	ID3Frame*		frame;
	ID3Field*		field;
	unsigned int	clen;
	
	if (str == NULL)
		return;
	
	clen = [str length];
	if (clen == 0)
		return;

	// Create the frame
	frame = ID3Frame_NewID(frameID);	
	if (frame == NULL) {
		free(ubuf);
		return;
	}

	// Encoding
	field = ID3Frame_GetField(frame, ID3FN_TEXTENC);	
	ID3Field_SetINT(field, ID3TE_UNICODE);
	
	// Text
	field = ID3Frame_GetField(frame, ID3FN_TEXT);
	ID3Field_SetEncoding(field, ID3TE_UNICODE);
//	ID3Field_SetUNICODE(field, (unicode_t*)ubuf);

	ID3Tag_AddFrame(tag, frame);
	
	free(ubuf);
}

- (BOOL)changeTagInFile:(NSString*)fpath toTags:(NSDictionary*)newTag
{
	ID3Tag* tag;
	ID3_Err errCode;

	tag = ID3Tag_New();
	if (tag == NULL) {
		NSLog(@"New failed");
		return FALSE;
	}
	
	ID3Tag_Link(tag, [fpath fileSystemRepresentation]);
	ID3Tag_Clear(tag);

	[self addFrameToTag:tag withID:ID3FID_LEADARTIST	usingText:[newTag objectForKey:ArtistIdent]];
	[self addFrameToTag:tag withID:ID3FID_ALBUM			usingText:[newTag objectForKey:AlbumIdent]];
	[self addFrameToTag:tag withID:ID3FID_TRACKNUM		usingText:[newTag objectForKey:TrackNumberIdent]];
	[self addFrameToTag:tag withID:ID3FID_TITLE			usingText:[newTag objectForKey:TrackTitleIdent]];
	[self addFrameToTag:tag withID:ID3FID_YEAR			usingText:[newTag objectForKey:YearIdent]];

	ID3Tag_SetPadding(tag, FALSE);
	ID3Tag_SetUnsync(tag, FALSE);
	
	errCode = ID3Tag_UpdateByTagType(tag, ID3TT_ID3V2);
	if (errCode != ID3E_NoError)
		NSLog(@"Update failed! %d", errCode);
	
	ID3Tag_Delete(tag);
	
	return TRUE;
}
*/

- (void)hexdump:(NSData*)data ofs:(unsigned)ofs length:(unsigned)len desc:(NSString*)desc
{
	unsigned		i;
	unsigned char*  ucptr;

	NSLog(desc);
	ucptr = (unsigned char*)[data bytes];
	for (i = 0; i < len; i++) {
		fprintf(stderr, "%02X(%c) ", ucptr[ofs+i], ucptr[ofs+i]);
		if (i % 16 == 0)
			fprintf(stderr, "\n");
	}
	fprintf(stderr, "\n");	
}

- (void)addID3v1EntryToData:(NSMutableData*)data usingTag:(NSDictionary*)newTag
				 usingIdent:(NSString*)ident maxLen:(unsigned)maxLen andPos:(unsigned)pos
{
	NSString* id3frameText = [newTag objectForKey:ident];
	if ([id3frameText length] > 0) {
		NSData*		td = [id3frameText dataUsingEncoding:NSISOLatin1StringEncoding];
		unsigned	tl = [td length];
		
		if (tl == 0) // Nothing left after data encoding
			return;
		
		if (tl > maxLen-1) // 30 - '\0'
			tl = maxLen-1;
		
		[data replaceBytesInRange:NSMakeRange(pos, tl) withBytes:[td bytes]];
	}
}

- (BOOL)changeTagInFile:(NSString*)fpath withOpts:(id)optObj
				 toTags:(NSDictionary*)newTag withOldTag:(NSDictionary*)oldTag
{
	// V2
	#define ID3V2_HEADER_SIZE 10
	static const unsigned char ID3v2Header[ID3V2_HEADER_SIZE] = {
		'I', 'D', '3',			// magic
		0x03, 0x00,				// version
		0x00,					// flags (no unsyc, no ext.header, no exp. indicator
		0x00, 0x00, 0x00, 0x00  // tag size (calculated later)
	};
	
	#define ENC_TAG_SIZE(UL) \
		(UL        & 0x0000007F) | \
		((UL << 1) & 0x00007F00) | \
		((UL << 2) & 0x007F0000) | \
		((UL << 3) & 0x7F000000)
	
	#define SET_TAG_SIZE(BUF, TS) \
		*((unsigned long*)(((void*)BUF)+6)) = htonl(ENC_TAG_SIZE(TS));
		
	#define ID3V2_FRAME_BEGIN_SIZE 11
	static unsigned char ID3v2FrameBegin[ID3V2_FRAME_BEGIN_SIZE] = {
		0x00, 0x00, 0x00, 0x00, // frame ID (z.b. TIT2)
        0x00, 0x00, 0x00, 0x00, // frame size
		0x00, 0x00,				// flags (preserve if altered)
		0x00,					// encoding
	};

	#define SET_FRAME_ID(ID) \
		*((unsigned long*)ID3v2FrameBegin) = *((unsigned long*)ID);
	
	#define SET_FRAME_SIZE(FS) \
		*((unsigned long*)&ID3v2FrameBegin[4]) = htonl(FS);

	#define ID3V2_ENCODING_ISO_8859_1   0x00
	#define ID3V2_ENCODING_UTF16		0x01

	#define SET_FRAME_ENCODING(ENC) \
		ID3v2FrameBegin[10] = ENC;
	
	#define ID3V2_NUM_COMMENT_FIELDS			4
	static unsigned char ID3v2NoLanguage[3] = {
		0x00, 0x00, 0x00
	};
		
	// V1
	#define ID3V1_TAG_SIZE 128
	static const char ID3v1Ident[3] = { 'T', 'A', 'G' };
	#define ID3V1_TAG_BYTE(VAR, POS, VALUE) \
		*((unsigned char*)([VAR mutableBytes]+POS)) = (unsigned char)VALUE;
	
	//
	NSMutableData*		tag;
	NSEnumerator*		en;
	NSString*			key, *id3frameID, *id3frameText;
	char				frameID[4+1];
	unsigned long		frameSize, tagSize;
	NSStringEncoding	useEnc;
	NSString*			workPath;	
	NSFileHandle*		inFH, *outFH;
	int					genreIndex = GENRE_CUSTOM;
	BOOL				isComment;
	NSDictionary*		cmtDict;
	unsigned			dataOfs;
	BOOL				createNewFile, moveOtherDir;
		
	tag = [NSMutableData dataWithBytes:ID3v2Header length:ID3V2_HEADER_SIZE];
	
	// Create all frames
	en = [newTag keyEnumerator];
	while (key = [en nextObject]) {
		id3frameID = [m_identToFrame objectForKey:key];
		if (id3frameID == nil)
			continue;
		
		if ([id3frameID isEqualToString:FrameCommentIdent]) {
			cmtDict	= [newTag objectForKey:key];
			if ((cmtDict == nil) || ([cmtDict count] != ID3V2_NUM_COMMENT_FIELDS))
				continue;
			isComment = TRUE;
		} else {
			id3frameText = [newTag objectForKey:key];
			if ([id3frameText length] == 0)
				continue;
			isComment = FALSE;			
		}
		
		// Frame header
		[id3frameID getCString:frameID maxLength:5];
		SET_FRAME_ID(frameID);
	
		// Comment frame contains more than a simple string...
		if (isComment) {
			NSString*	st		= [cmtDict objectForKey:CommentShortTextIdent],
						*ft		= [cmtDict objectForKey:CommentFullTextIdent],
						*lang	= [cmtDict objectForKey:CommentLanguageIdent];
			char		tenc	= [[cmtDict objectForKey:CommentTextEncIdent] charValue];
			
			frameSize = [st length] + [ft length] + 5; // 5 = enc, lang(3), '\0'
						
			SET_FRAME_SIZE(frameSize);
			[tag appendBytes:ID3v2FrameBegin length:ID3V2_FRAME_BEGIN_SIZE];
			
			SET_FRAME_ENCODING(tenc);

			if ([lang length] == 0)
				[tag appendBytes:ID3v2NoLanguage length:3];
			else
				[tag appendBytes:[lang cString] length:3];

			[tag appendData:[st dataUsingEncoding:NSISOLatin1StringEncoding]];
			[tag appendBytes:ID3v2NoLanguage length:1];
			[tag appendData:[ft dataUsingEncoding:NSISOLatin1StringEncoding]];

		// Not a comment frame
		} else {
			// Genre
			if (id3frameID == FrameGenreIdent) {
				genreIndex = v1GenreFromString(id3frameText);
				if (genreIndex != GENRE_CUSTOM)
					id3frameText = [NSString stringWithFormat:@"(%d)", genreIndex]; // itunes only ?
			}
		
/*			// Latin1 encoding
			if ([id3frameText canBeConvertedToEncoding:NSISOLatin1StringEncoding]) {
				frameSize = [id3frameText length]+2; // +2 = latin1-ID, '\0'
				useEnc = NSISOLatin1StringEncoding;
				SET_FRAME_ENCODING(ID3V2_ENCODING_ISO_8859_1);
				
				NSLog(@"can be encoded with latin 1");
			
			// UTF16 encoding
			} else {
*/				
				frameSize = (([id3frameText length]+1) << 1)+3; // +3 = UTF16-ID, UTF-endianess (2 byte)
				useEnc = NSUnicodeStringEncoding;
				SET_FRAME_ENCODING(ID3V2_ENCODING_UTF16);
//			}
		
			SET_FRAME_SIZE(frameSize);
			[tag appendBytes:ID3v2FrameBegin length:ID3V2_FRAME_BEGIN_SIZE];
		
			// Now the text
			[tag appendData:[id3frameText dataUsingEncoding:useEnc]];
			if (useEnc == NSUnicodeStringEncoding)
				[tag increaseLengthBy:2]; // 0-termination
			else
				[tag increaseLengthBy:1];
		}
	}
	
	dataOfs = [[oldTag objectForKey:DataOfsIdent] unsignedIntValue]; // = Size of prev. v1 tag
	
	// Padding
	if (dataOfs >= [tag length]) {
		createNewFile = FALSE;

		[tag increaseLengthBy:(dataOfs - [tag length])];
	} else {
		createNewFile = TRUE;
		
		if ([optObj padTag]) {
			unsigned padsize, fsize = [[oldTag objectForKey:DataSizeIdent] unsignedIntValue]; // datasize
			fsize += [tag length];
			if ([optObj generateV1Tag])
				fsize += ID3V1_TAG_SIZE;

			padsize = fsize % PaddingAssumedBlockSize;
			if (padsize < PaddingMinPadSize)
				padsize = PaddingAssumedBlockSize;
				
			[tag increaseLengthBy:padsize];
		}
	}
	
//	NSLog(@"creating new file... = %d", createNewFile);
	
	// Fix the tag size
	tagSize = [tag length] - ID3V2_HEADER_SIZE;
	SET_TAG_SIZE([tag mutableBytes], tagSize);
	
	// Create a new file w/ the v2 tag and the data
	if (createNewFile) {
		// Write the tag
		workPath = [fpath stringByAppendingString:@"-tritag"];
		if (![m_fileManager createFileAtPath:workPath contents:tag attributes:nil])
			return FALSE;
	
		// Copy the mp3 data itself	
		inFH = [NSFileHandle fileHandleForReadingAtPath:fpath];
		if (inFH == NULL) {
			NSBeginAlertSheet(@"File permissions", @"Skip file", nil, nil,
							[NSApp mainWindow], self, nil, nil, nil,
							@"Failed to reopen '%@'", fpath);
			[m_fileManager removeFileAtPath:workPath handler:nil];
			return FALSE;
		}
		
		[inFH seekToFileOffset:[[oldTag objectForKey:DataOfsIdent] unsignedLongLongValue]];
		outFH = [NSFileHandle fileHandleForUpdatingAtPath:workPath];
		[outFH seekToEndOfFile];
	
		[outFH writeData:
			[inFH readDataOfLength:[[oldTag objectForKey:DataSizeIdent] unsignedIntValue]]];
	
		[inFH closeFile];

	// Just overwrite the old tag
	} else {
		outFH	= [NSFileHandle fileHandleForUpdatingAtPath:fpath]; // seeks to 0
		[outFH writeData:tag];
	}

	// Also generate v1 tag if wanted
	if ([optObj generateV1Tag]) {
		int trackNo;
		
		tag = [NSMutableData dataWithLength:ID3V1_TAG_SIZE];
		
		[tag replaceBytesInRange:NSMakeRange(0, 3) withBytes:ID3v1Ident];

		[self addID3v1EntryToData:tag usingTag:newTag usingIdent:TrackTitleIdent maxLen:30 andPos:3];
		[self addID3v1EntryToData:tag usingTag:newTag usingIdent:ArtistIdent maxLen:30 andPos:33];
		[self addID3v1EntryToData:tag usingTag:newTag usingIdent:AlbumIdent maxLen:30 andPos:63];
		[self addID3v1EntryToData:tag usingTag:newTag usingIdent:YearIdent maxLen:5 andPos:93];
	
		// IDv1.1 track no
		id3frameText = [newTag objectForKey:TrackNumberIdent];
		if ([id3frameText length] > 0) {
			trackNo = [id3frameText intValue];
			if ((trackNo >= 0) && (trackNo <= 255)) // {
				ID3V1_TAG_BYTE(tag, 126, trackNo);
//				*((unsigned char*)([tag mutableBytes]+126)) = (unsigned char)trackNo;
//			}
		}
		
		// Genre - only when v1 compatible
		if (genreIndex != GENRE_CUSTOM) 
			ID3V1_TAG_BYTE(tag, 127, genreIndex);

		if (!createNewFile) {
			if ([[oldTag objectForKey:HasV1TagIdent] boolValue])
				[outFH seekToFileOffset:[[oldTag objectForKey:V1TagOfsIdent] unsignedIntValue]];
			else
				[outFH seekToEndOfFile];
		}
	
		[outFH writeData:tag];
	
	// Truncate if V1 exists but isn't wanted anymore
	} else if (!createNewFile && [[oldTag objectForKey:HasV1TagIdent] boolValue])
		[outFH truncateFileAtOffset:[[oldTag objectForKey:V1TagOfsIdent] unsignedIntValue]];
			
	[outFH closeFile];
	
	// Ok replace the old with the new one
	if (createNewFile) {
		if (![m_fileManager removeFileAtPath:fpath handler:nil])
			return FALSE;
	}
	
	moveOtherDir = (BOOL)([optObj outDirectory] != nil);
	if (moveOtherDir) {
		[self _createDirectoryRecursive:[optObj outDirectory]];
		fpath = [[optObj outDirectory] stringByAppendingPathComponent:[fpath lastPathComponent]];
	}
	
	if (createNewFile || moveOtherDir)
		[m_fileManager movePath:workPath toPath:fpath handler:nil];
	
	return TRUE;
}

/*
// Unused code.. id3tag lib
 
- (BOOL)changeTagInFile:(NSString*)fpath toTags:(NSDictionary*)newTag withOldTag:(NSDictionary*)oldTag
{
	struct  id3_tag*		itag;
	struct	id3_frame*		aframe;
	id3_ucs4_t*				strUCS4;
	unsigned				ftlen;
	unichar*				strUTF16;
	NSEnumerator*			en;
	NSString*				key, *id3frameDesc, *id3frameText;
	unsigned long			tagSize;
	char*					tagBuf;
	NSString*				workPath;
	NSFileHandle*			inFH, *outFH;
	NSData*					data;
	
	if ((fpath == nil) || ([fpath length] == 0))
		return FALSE;
	
	// Create the tag
	itag = id3_tag_new();
	if (itag == NULL)
		return FALSE;
	
	// Create all frames
	en = [newTag keyEnumerator];
	while (key = [en nextObject]) {
		id3frameDesc = [m_identToFrame objectForKey:key];
		if (id3frameDesc == nil)
			continue;

		id3frameText = [newTag objectForKey:key];
		ftlen = [id3frameText length];
		if (ftlen == 0)
			continue;
		
		aframe = id3_frame_new([[m_identToFrame objectForKey:key] cString]);
		if (aframe == NULL) {
			NSLog(@"frame = NULL");
			return FALSE;
		}
		
		id3_field_settextencoding(&aframe->fields[0], ID3_FIELD_TEXTENCODING_UTF_16);

		strUTF16 = (unichar*)malloc((ftlen+1) << 1);
		[id3frameText getCharacters:strUTF16];
		strUTF16[ftlen] = '\0';

		strUCS4 = id3_utf16_ucs4duplicate(strUTF16);
		free(strUTF16);
		id3_field_setstrings(&aframe->fields[1], 1, &strUCS4);
		free(strUCS4);
		
		id3_tag_attachframe(itag, aframe);		
	}

	// Options (from Audicity)
	itag->options &= (~ID3_TAG_OPTION_COMPRESSION); // No compression
	#ifdef ID3_TAG_OPTION_ID3V2_3 
		itag->options |= ID3_TAG_OPTION_ID3V2_3;
	#endif

	// Render the whole v2 tag into a allocated buffer
	tagSize = id3_tag_render(itag, NULL);
	tagBuf = (char*)malloc(tagSize);
	if (tagBuf == NULL) { // uuh the times of memory errors should be over
		NSLog(@"malloc failed");
		id3_tag_delete(itag);
		return FALSE;
	}
	id3_tag_render(itag, tagBuf);
	id3_tag_delete(itag);
	
	// Generate the new .mp3 with the header
	workPath = [fpath stringByAppendingString:@"-tritag"];
	data = [NSData dataWithBytes:tagBuf length:tagSize];
	free(tagBuf);
	if (![m_fileManager createFileAtPath:workPath contents:data attributes:nil])
		return FALSE;

	// Append the MP3 data itself to the file
	inFH = [NSFileHandle fileHandleForReadingAtPath:fpath];
	if (inFH == NULL) {
		NSBeginAlertSheet(@"File permissions", @"Skip file", nil, nil,
						  [NSApp mainWindow], self, nil, nil, nil,
						  @"Failed to reopen '%@'", fpath);
		[m_fileManager removeFileAtPath:workPath handler:nil];
		return FALSE;
	}
	[inFH seekToFileOffset:[[oldTag objectForKey:DataOfsIdent] unsignedLongLongValue]];
	outFH = [NSFileHandle fileHandleForUpdatingAtPath:workPath];
	[outFH seekToEndOfFile];

	data = [inFH readDataOfLength:[[oldTag objectForKey:DataSizeIdent] unsignedIntValue]];
	[outFH writeData:data];
	
	[inFH closeFile];
	[outFH closeFile];

	// Ok replace the old with the new one
	if (![m_fileManager removeFileAtPath:fpath handler:nil])
		return FALSE;
	
	[m_fileManager movePath:workPath toPath:fpath handler:nil];
	
	// Way to go
	return TRUE;
}
*/
- (void)allFilenamesToTagsForPattern:(NSString*)patStr withOpts:(id)optObj shouldApply:(BOOL)apply
{
	FFFilenameToTag*		ftt;
	unsigned				i;
	NSString*				fpath;
	NSDictionary*			oldTag, *exTag;
	NSMutableDictionary*	mxTag;
	BOOL					entryWasRemoved;
	
	ftt = [[FFFilenameToTag alloc] initWithString:[patStr stringByAppendingPathExtension:FileExtension] withOpts:optObj];
	if (ftt == nil)
		return;

	i = 0;
	while (i < [m_tableArray count]) {
		// Filename -> Tag
		entryWasRemoved = FALSE;
		fpath = [self stringForRow:i andIdent:FilePathIdent];
		exTag = [ftt tagFromFilename:[fpath lastPathComponent]];
		
		// Merge with existing data or erase empty columns
		oldTag = [m_tableArray objectAtIndex:i];
		if ([optObj keepColumnDataIfEmpty])
			mxTag = [NSMutableDictionary dictionaryWithDictionary:oldTag];
		else
			mxTag = [NSMutableDictionary dictionaryWithDictionary:m_emptyIdentRow];

		if (exTag != nil)
			[mxTag addEntriesFromDictionary:exTag];

		// Default values
		[self _InsertDefaultValuesIntoDictionary:mxTag withOpts:optObj];
		
		// Update or just plain preview
		if (exTag != nil) {
			if (apply) {
				if ([self changeTagInFile:fpath withOpts:optObj toTags:mxTag withOldTag:oldTag]) {
					[m_tableArray removeObjectAtIndex:i];
					entryWasRemoved = TRUE;
				}
			} else
				[[m_tableArray objectAtIndex:i] addEntriesFromDictionary:mxTag];
		}

		if (!entryWasRemoved)
			i++;
	}
}

- (void)allToTagsWithOpts:(id)optObj { // Heavily based on allFilenamesToTags
	unsigned				i;
	NSMutableDictionary*	mxTag;
	
	i = 0;
	while (i < [m_tableArray count]) {
		mxTag	= [NSMutableDictionary dictionaryWithDictionary:[m_tableArray objectAtIndex:i]];
		[self _InsertDefaultValuesIntoDictionary:mxTag withOpts:optObj];
		
		// Apply
		(void)[self changeTagInFile:[mxTag objectForKey:FilePathIdent] 
						   withOpts:optObj toTags:mxTag withOldTag:mxTag];
		i++;
	}
}

#pragma mark -
#pragma mark Modifying the tracks

- (void)setTrackWithNo:(int)trackNo toArtist:(NSString*)artist album:(NSString*)album
			trackTitle:(NSString*)title andYear:(NSString*)year {

	NSString*				tnas	= [NSString stringWithFormat:@"%d", trackNo];
	NSEnumerator*			en		= [m_tableArray objectEnumerator];
	NSMutableDictionary*	row;
	
	while (row = [en nextObject]) {
		if ([[row objectForKey:TrackNumberIdent] isEqualToString:tnas]) {
			[row setObject:artist forKey:ArtistIdent];
			[row setObject:album forKey:AlbumIdent];
			[row setObject:title forKey:TrackTitleIdent];
			[row setObject:year forKey:YearIdent];
			break;
		}
	}
}

#pragma mark -
#pragma mark FreeDB

#if 0

- (void)_calcDurations {
	NSEnumerator*			en = [m_tableArray objectEnumerator];
	NSMutableDictionary*	fd;
	
	while (fd = [en nextObject])
		[fd setObject:[NSNumber numberWithInt:mp3len([[fd objectForKey:FilePathIdent] fileSystemRepresentation])] forKey:FDBDurationIdent];
}

static int _durationComparator(id e1, id e2, void* contex) {
	return [(NSNumber*)[e1 objectForKey:FDBDurationIdent] compare:(NSNumber*)[e2 objectForKey:FDBDurationIdent]];
}

- (void)_updateTable:(NSDictionary*)fdb {
	NSString*				artist	= [fdb objectForKey:FDBArtistIdent];
	NSString*				album	= [fdb objectForKey:FDBAlbumIdent];
	NSString*				year	= [fdb objectForKey:FDBYearIdent];
	NSEnumerator*			te		= [m_tableArray objectEnumerator];
	NSEnumerator*			fe		= [[fdb objectForKey:FDBTracksIdent] objectEnumerator];
	NSMutableDictionary*	td;
	NSDictionary*			fd;
	
	while (td = [te nextObject]) {
		fd = [fe nextObject];

		[td setObject:artist forKey:ArtistIdent];
		[td setObject:album forKey:AlbumIdent];
		[td setObject:year forKey:YearIdent];
		
		[td setObject:[fd objectForKey:FDBTrackNoIdent] forKey:TrackNumberIdent];
		[td setObject:[fd objectForKey:FDBTrackTitleIdent] forKey:TrackTitleIdent];
	}
}

static int _trackNoComparator(id e1, id e2, void* contex) { // Not optimal but it works..
	if ([[e1 objectForKey:TrackNumberIdent] intValue] < [[e2 objectForKey:TrackNumberIdent] intValue])
		return NSOrderedAscending;
	
	return NSOrderedDescending; // No NSOrderedSame
}

- (void)updateWithFreeDBData:(NSDictionary*)fdb {
	if ([m_tableArray count] != [[fdb objectForKey:FDBTracksIdent] count])
		NSRunAlertPanel(@"Number of tracks differs",
						@"# of tracks in the table and the FreeDB details must be the same.",
						@"OK", nil, nil);
	else {
		[self _calcDurations];
		[m_tableArray sortUsingFunction:_durationComparator context:NULL];
		[[fdb objectForKey:FDBTracksIdent] sortUsingFunction:_durationComparator context:NULL];
		[self _updateTable:fdb];
		[m_tableArray sortUsingFunction:_trackNoComparator context:NULL];
	}
}

#endif

@end
