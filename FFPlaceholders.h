// $Id: FFPlaceholders.h 234 2004-07-31 13:55:31Z ravemax $

typedef enum {
	PH_ARTIST = 0,
	PH_ALBUM,
	PH_TRACK_NUMBER,
	PH_TRACK_TITLE,
	PH_YEAR,
	PH_GENRE,
	
	PH_NUM_IDENTS
} PlaceholderIdentifiers;

extern NSString* ArtistIdent;
extern NSString* AlbumIdent;
extern NSString* TrackNumberIdent;
extern NSString* TrackTitleIdent;
extern NSString* YearIdent;
extern NSString* GenreIdent;

typedef struct {
	NSString*	ident;
	unsigned	pos;
} PlaceHolder;

@interface FFPlaceholders : NSObject
{
	NSMutableString*	m_str;
	unsigned			m_num;
	PlaceHolder			m_phs[PH_NUM_IDENTS];
}

+ (char)placeholderNo:(unsigned)no;

- (id)initWithString:(NSString*)str;

- (NSMutableString*)getString;
- (unsigned)numberOfUsedIdents;
- (NSString*)identAtIndex:(unsigned)idx;
- (unsigned)positionAtIndex:(unsigned)idx;


@end
