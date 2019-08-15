// $Id: FFData.h 259 2004-08-18 12:26:05Z ravemax $

extern NSString* FilePathIdent;

@interface FFData : NSObject
{
	NSMutableArray*	m_tableArray;
}

- (id)init;

- (void)addFiles:(NSArray*)files;
- (void)removeAllFiles;

- (unsigned)numOfRows;
- (NSString*)stringForRow:(unsigned)row andIdent:(NSString*)ident;
- (void)setStringForRow:(unsigned)row andIdent:(NSString*)ident toString:(NSString*)tostr;

- (void)allTagsToFolderSortedFilenamesForPattern:(NSString*)patStr withOpts:(id)optObj;
- (void)allTagsToFilenamesForPattern:(NSString*)patStr withOpts:(id)optObj shouldApply:(BOOL)apply;
- (void)allFilenamesToTagsForPattern:(NSString*)patStr withOpts:(id)optObj shouldApply:(BOOL)apply;
- (void)allToTagsWithOpts:(id)optObj; // apply = TRUE

- (void)setTrackWithNo:(int)trackNo toArtist:(NSString*)artist album:(NSString*)album
			trackTitle:(NSString*)title andYear:(NSString*)year;

- (void)updateWithFreeDBData:(NSDictionary*)fdb;

@end
