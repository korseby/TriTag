// $Id: FFFreeDB.h 264 2004-08-20 14:22:11Z ravemax $

@class FFPreferences;
@class FFProgress;

// Idents for the returned dict
extern NSString*	FDBArtistIdent;
extern NSString*	FDBAlbumIdent;
extern NSString*	FDBYearIdent;
extern NSString*	FDBTracksIdent;
extern NSString*	FDBTrackNoIdent;
extern NSString*	FDBDurationIdent;
extern NSString*	FDBTrackTitleIdent;


#define FREEDB_MAX_MATCHES	100

@interface FFFreeDB : NSObject {
    IBOutlet NSWindow*		m_mainWin;
    IBOutlet NSWindow*		m_searchWin;
    IBOutlet NSWindow*		m_albumsWin;
    IBOutlet NSTextField*	m_searchText;
    IBOutlet NSTableView*	m_albumsTable;
	IBOutlet NSButton*		m_showPrevResBtn;
	
	IBOutlet FFPreferences*	m_prefs;
	IBOutlet FFProgress*	m_progress;

	NSMutableArray*			m_albums;
}

// IB Actions
- (IBAction)acceptSelection:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)showPrevResults:(id)sender;

// 
- (NSDictionary*)go;


@end
