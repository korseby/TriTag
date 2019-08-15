// $Id: FFController.h 264 2004-08-20 14:22:11Z ravemax $

#import "FFPlaceholders.h"

@class FFData;
@class FFDropWindow;
@class FFFreeDB;
@class FFPreferences;
@class FFProgress;

typedef enum {
	TO_TAG_MODE = 0,
	TO_FILENAME_MODE,
	TO_TAG_AND_FILENAME_MODE
} ActionMode;

@interface FFController : NSObject
{
	// Main window
	IBOutlet NSWindow*				m_mainWindow;
    IBOutlet NSTableView*			m_fileTable;
    IBOutlet NSPopUpButton*			m_mode;
    IBOutlet NSTextField*			m_patternField;
	IBOutlet FFDropWindow*			m_window;
	IBOutlet NSButton*				m_autoTrackNumBtn;

	IBOutlet NSBox*					m_optBox;
	IBOutlet NSView*				m_toTagView;
	IBOutlet NSView*				m_toFilenameView;
	IBOutlet NSView*				m_toTagAndFilenameView;

    IBOutlet NSButton*				m_optToTagUnderscore;
	IBOutlet NSButton*				m_optToTagDots;
	IBOutlet NSButton*				m_optToTagKeepData;
	IBOutlet NSButton*				m_optToTagV1Tag;
	IBOutlet NSButton*				m_optToTagPadTag;
	IBOutlet NSButton*				m_optToFilenameSpace;
	IBOutlet NSButton*				m_optToFilenameFolders;
	IBOutlet NSButton*				m_optToBothSpace;
	IBOutlet NSButton*				m_optToBothFolders;
	IBOutlet NSButton*				m_optToBothV1Tag;
	IBOutlet NSButton*				m_optToBothPadTag;

	IBOutlet NSButton*				m_forceDefaults;
	IBOutlet NSTextField*			m_defaultArtist;
	IBOutlet NSTextField*			m_defaultAlbum;	
	IBOutlet NSTextField*			m_defaultYear;
	IBOutlet NSComboBox*			m_defaultGenre;
	
	// Pattern builder
	IBOutlet NSWindow*				m_pbWindow;
	IBOutlet NSTextView*			m_pbFilename;
	IBOutlet NSPopUpButton*			m_pbDescriptions;
	
	// Edit
	IBOutlet NSWindow*				m_editWin;
	IBOutlet NSButton*				m_editButton;
	IBOutlet NSMenuItem*			m_editMenuItem;
	IBOutlet NSTextField*			m_editArtist;
	IBOutlet NSButton*				m_editArtistCheck;
	IBOutlet NSTextField*			m_editAlbum;
	IBOutlet NSButton*				m_editAlbumCheck;
	IBOutlet NSTextField*			m_editYear;
	IBOutlet NSButton*				m_editYearCheck;
	IBOutlet NSComboBox*			m_editGenre;
	IBOutlet NSButton*				m_editGenreCheck;
	
	// FreeDB
	IBOutlet FFFreeDB*				m_freeDB;
		
	// Misc
	IBOutlet FFPreferences*			m_prefs;
	IBOutlet FFProgress*			m_progress;
	
	// Additional internal variables
	FFData*							m_data;
	NSRange							m_pbParts[PH_NUM_IDENTS];
	NSMutableArray*					m_genres;
	NSMutableArray*					m_userGenres;
	NSString*						m_outDir;
}

// IB Actions : main window
- (IBAction)apply:(id)sender;
- (IBAction)preview:(id)sender;
- (IBAction)clearList:(id)sender;
- (IBAction)checkUpdate:(id)sender;
- (IBAction)sendFeedback:(id)sender;
- (IBAction)showPatternBuilder:(id)sender;
- (IBAction)showHelpWithBrowser:(id)sender;
- (IBAction)modeChanged:(id)sender;
- (IBAction)goFreeDB:(id)sender;
- (IBAction)showEditSelected:(id)sender;
- (IBAction)autoNumberTrackNo:(id)sender;

// Options
- (BOOL)convertSpaceToUnderscore;
- (BOOL)convertUnderscoreToSpace;
- (BOOL)convertDotToSpace;
- (BOOL)keepColumnDataIfEmpty;
- (BOOL)sortIntoFolders;
- (BOOL)generateV1Tag;
- (BOOL)padTag;
- (NSString*)outDirectory;

// The default values
- (BOOL)forceDefaultValues;
- (NSString*)defaultArtist;
- (NSString*)defaultAlbum;
- (NSString*)defaultYear;
- (NSString*)defaultGenre;

// Exported because GCC 3.3 (XCode) broke some code in FFDropWindow
- (void)filesWereDropped:(NSArray*)files;

// Pattern builder methods
- (void)pbResetPartNo:(unsigned)no;
- (void)pbResetAllParts;
- (BOOL)pbAnyTextSelected;
- (void)pbUpdatePartNo:(unsigned)no;
- (NSString*)pbGetNewPattern;

// IB Actions : pattern builder
- (IBAction)pbDescriptionSelected:(id)sender;
- (IBAction)pbResetAll:(id)sender;
- (IBAction)pbClose:(id)sender;
- (IBAction)pbCloseAndAdopt:(id)sender;

// IB Actions : Edit selected
- (IBAction)editCancel:(id)sender;
- (IBAction)editAccept:(id)sender;

@end
