RCS_ID("$Id: FFController.m 264 2004-08-20 14:22:11Z ravemax $")

#import "FFController.h"
#import "FFData.h"
#import "FFPlaceholders.h"
#import "FFDropWindow.h"
#import "FFSupport.h"
#import "FFStringAdditions.h"
#import "FFV1Genres.h"
#import "FFScriptCommand.h"
#import "FFFreeDB.h"
#import "FFProgress.h"

@implementation FFController

// Pattern constants
#define PB_ADOPT_PATTERN	1
#define PB_DISCARD_PATTERN  2

static NSColor* PBPartColors[PH_NUM_IDENTS] = {0};

// Edit selected constants
#define EDSEL_CANCEL	0
#define EDSEL_ACCEPT	1

// User default keys
static NSString* UDKeyPattern			= @"udn_pattern";
static NSString* UDKeyToTagUnderscore   = @"udn_underscore";
static NSString* UDKeyToTagDots			= @"udn_dots";
static NSString* UDKeyToTagKeepData		= @"udn_keep_data";
static NSString* UDKeyToTagV1Tag		= @"udn_v1_tag";
static NSString* UDKeyToTagPadTag		= @"udn_pad_tag";
static NSString* UDKeyToFilenameSpace   = @"udn_space";
static NSString* UDKeyToFilenameFolders = @"udn_filename";
static NSString* UDKeyMode				= @"udn_mode";
static NSString* UDKeyGenre				= @"udn_genre";
static NSString* UDKeyUserGenres		= @"udn_user_genres";

/*
 *  Init ...
 */
+ (void)initialize
{
	if (PBPartColors[0] == 0) {
		PBPartColors[PH_ARTIST]			= [NSColor blueColor];
		PBPartColors[PH_ALBUM]			= [NSColor greenColor];
		PBPartColors[PH_TRACK_NUMBER]	= [NSColor magentaColor];
		PBPartColors[PH_TRACK_TITLE]	= [NSColor redColor];
		PBPartColors[PH_YEAR]			= [NSColor brownColor];
		PBPartColors[PH_GENRE]			= [NSColor orangeColor];
	}
}

- (void)_setOptionView:(NSView*)optView
{	
	[m_optBox setContentView:optView];
}

- (void)_readPrefs {
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	
	[ud registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		@"", UDKeyPattern,
		[NSNumber numberWithInt:NSOffState], UDKeyToTagUnderscore,
		[NSNumber numberWithInt:NSOffState], UDKeyToTagDots,
		[NSNumber numberWithInt:NSOffState], UDKeyToTagKeepData,
		[NSNumber numberWithInt:NSOffState], UDKeyToTagV1Tag,
		[NSNumber numberWithInt:NSOffState], UDKeyToTagPadTag,
		[NSNumber numberWithInt:NSOffState], UDKeyToFilenameSpace,
		[NSNumber numberWithInt:NSOffState], UDKeyToFilenameFolders,
		[NSNumber numberWithInt:0], UDKeyMode,
		@"Rock", UDKeyGenre,
		[NSArray array], UDKeyUserGenres,
		nil]];
	
	[m_patternField setStringValue:[ud stringForKey:UDKeyPattern]];
		
	[m_optToTagUnderscore   setState:[ud integerForKey:UDKeyToTagUnderscore]];
	[m_optToTagDots			setState:[ud integerForKey:UDKeyToTagDots]];
	[m_optToTagKeepData		setState:[ud integerForKey:UDKeyToTagKeepData]];
	[m_optToTagV1Tag		setState:[ud integerForKey:UDKeyToTagV1Tag]];
	[m_optToTagPadTag		setState:[ud integerForKey:UDKeyToTagPadTag]];
	[m_optToFilenameSpace   setState:[ud integerForKey:UDKeyToFilenameSpace]];
	[m_optToFilenameFolders setState:[ud integerForKey:UDKeyToFilenameFolders]];

	[m_optToBothSpace setState:[m_optToFilenameSpace state]];
	[m_optToBothFolders setState:[m_optToFilenameFolders state]];
	[m_optToBothV1Tag setState:[m_optToTagV1Tag state]];
	[m_optToBothPadTag setState:[m_optToTagPadTag state]];

	[m_mode selectItemAtIndex:[ud integerForKey:UDKeyMode]];
	[self modeChanged:self];
	
	// Genre
	m_userGenres = [[NSMutableArray alloc] initWithArray:[ud stringArrayForKey:UDKeyUserGenres]];
	[m_genres addObjectsFromArray:m_userGenres];
	[m_genres sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[m_defaultGenre reloadData];
	[m_defaultGenre setStringValue:[ud stringForKey:UDKeyGenre]];
}

- (void)awakeFromNib
{
	// main window
	m_data = [[FFData alloc] init];
	[m_fileTable setDataSource:m_data];
	[m_fileTable setDelegate:m_data];
	
	[m_window setDropObject:self andSelector:@selector(filesWereDropped:)];
	[m_optBox setContentViewMargins:NSMakeSize(-5.0, -5.0)]; // Dirty hack
	[NSApp setDelegate:self];
	
	m_outDir = nil;

	// Genre combox boxes
	m_genres = [[NSMutableArray alloc] initWithArray:v1Genres()];
	[m_defaultGenre setUsesDataSource:TRUE];
	[m_defaultGenre setDataSource:self];
	[m_defaultGenre setCompletes:TRUE];

	[m_editGenre setUsesDataSource:TRUE];
	[m_editGenre setDataSource:self];
	[m_editGenre setCompletes:TRUE];
	
	[self _readPrefs];

	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(scriptCommandReceived:) 
			   name:ScriptCommandReceived object:nil];
	[nc addObserver:self selector:@selector(fileTableSelectionDidChangeNotification:) 
			   name:NSTableViewSelectionDidChangeNotification object:m_fileTable];
	
	
}

- (void)applicationWillTerminate:(NSNotification*)notification {
	// Store user defaults
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	
	[ud setObject:[m_patternField stringValue] forKey:UDKeyPattern];
	
	[ud setInteger:[m_optToTagUnderscore state] forKey:UDKeyToTagUnderscore];
	[ud setInteger:[m_optToTagDots state] forKey:UDKeyToTagDots];
	[ud setInteger:[m_optToTagKeepData state] forKey:UDKeyToTagKeepData];
	[ud setInteger:[m_optToTagV1Tag state] forKey:UDKeyToTagV1Tag];
	[ud setInteger:[m_optToTagPadTag state] forKey:UDKeyToTagPadTag];
	[ud setInteger:[m_optToFilenameSpace state] forKey:UDKeyToFilenameSpace];
	[ud setInteger:[m_optToFilenameFolders state] forKey:UDKeyToFilenameFolders];	

	[ud setInteger:[m_mode indexOfSelectedItem] forKey:UDKeyMode];
	
	[ud setObject:m_userGenres forKey:UDKeyUserGenres];
	[ud setObject:[m_defaultGenre stringValue] forKey:UDKeyGenre];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[m_data release];
	[m_userGenres release];
	[m_genres release];
	
	[super dealloc];
}

- (ActionMode)activeMode {
	return [m_mode indexOfSelectedItem];
}

/*
 *  IB Actions : main window
 */

- (IBAction)modeChanged:(id)sender
{
	if ([self activeMode] == TO_TAG_AND_FILENAME_MODE) {
		[self _setOptionView:m_toTagAndFilenameView];
	} else {
		if ([self activeMode] == TO_TAG_MODE)
			[self _setOptionView:m_toTagView];
		else 
			[self _setOptionView:m_toFilenameView];
	}		
}

- (IBAction)clearList:(id)sender
{
	[m_data removeAllFiles];
	[m_fileTable reloadData];
}

- (void)_allTo:(BOOL)apply
{
	NSString* patStr = [m_patternField stringValue];
	
	if ([patStr length] > 0) {
		if ([self activeMode] == TO_TAG_MODE)
			[m_data allFilenamesToTagsForPattern:patStr withOpts:self shouldApply:apply];
		else if ([self activeMode] == TO_FILENAME_MODE) {
			if (apply && [self sortIntoFolders])
				[m_data allTagsToFolderSortedFilenamesForPattern:patStr withOpts:self];
			else
				[m_data allTagsToFilenamesForPattern:patStr withOpts:self shouldApply:apply];
		} else { // TO_TAG_AND_FILENAME_MODE
			if (apply) {
				[m_data allToTagsWithOpts:self];
				if ([self sortIntoFolders])
					[m_data allTagsToFolderSortedFilenamesForPattern:patStr withOpts:self];
				else
					[m_data allTagsToFilenamesForPattern:patStr withOpts:self shouldApply:TRUE];
			} else
				[m_data allTagsToFilenamesForPattern:patStr withOpts:self shouldApply:FALSE]; // Only filenames
		}

		// Store user genre
		if (apply && ([[self defaultGenre] length] > 0) && 
			(v1GenreFromString([self defaultGenre]) == GENRE_CUSTOM)) {
			if (![m_userGenres containsObject:[self defaultGenre]]) {
				[m_userGenres addObject:[self defaultGenre]];

				// Insert sorted into the combobox
				int idx;
				for (idx = 0; idx < [m_genres count]; idx++)
					if ([(NSString*)[m_genres objectAtIndex:idx] compare:[self defaultGenre]] == NSOrderedDescending)
						break;

				[m_genres insertObject:[self defaultGenre] atIndex:idx];
				[m_defaultGenre reloadData];
			}
		}
		
		[m_fileTable reloadData];
	}
}

- (IBAction)preview:(id)sender {
	[m_progress startWithText:@"Creating preview..."];
	[self _allTo:FALSE];
	[m_progress stop];
}

- (IBAction)apply:(id)sender {
	[m_progress startWithText:@"Applying..."];
	[self _allTo:TRUE];
	[m_progress stop];	
}

- (void)filesWereDropped:(NSArray*)files
{
	[m_progress startWithText:@"Adding files..."];
	[m_data addFiles:files];
	[m_progress stop];
	
	[m_fileTable reloadData];
}

- (IBAction)checkUpdate:(id)sender
{
	[FFSupport updatesCheckForProject:@"tritag"];
}

- (IBAction)sendFeedback:(id)sender
{
	[FFSupport sendFeedbackToMailaddress:@"patrick@feedface.com"];
}

- (IBAction)showPatternBuilder:(id)sender {
	int srow;
	
	// Check if a row (= filename) is selected - if not then select the first one (if available
	srow = [m_fileTable selectedRow];
	if (srow == -1) {
		if ([m_data numOfRows] == 0) {
			NSBeginInformationalAlertSheet(@"File table is empty",
			@"Ok", nil, nil, [NSApp mainWindow], self, nil, nil, NULL,
			@"You have to add atleast one file before you can use the 'Pattern builder.'");
			return;
		}
		srow = 0;
	}

	// Ok show the sheet (uuh mixing data and view .. dirty)
	// get the filename w/o suffix and paste it into the PB textview
	[m_pbFilename setString:		
		[[[[m_data stringForRow:srow andIdent:FilePathIdent] pathComponents] lastObject] stringByDeletingPathExtension]]; 
		
	[self pbResetAllParts];
	
	[NSApp beginSheet:m_pbWindow modalForWindow:m_mainWindow modalDelegate:self 
	   didEndSelector:@selector(patternBuilderSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (void)patternBuilderSheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode
					  contextInfo:(void*)contextInfo 
{
    [m_pbWindow orderOut:self];
	
	if (returnCode == PB_ADOPT_PATTERN)
		[m_patternField setStringValue:[self pbGetNewPattern]];
}

- (IBAction)showHelpWithBrowser:(id)sender {
	NSString*   helpFolder  = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleHelpBookFolder"];
	NSString*   rsrcPath	= [[NSBundle mainBundle] resourcePath];
	NSString*   indexPath   = [NSString stringWithFormat:@"%@/English.lproj/%@/%@.html",
								rsrcPath, helpFolder, helpFolder];
	
	(void)[[NSWorkspace sharedWorkspace] openFile:indexPath];
}	

- (IBAction)goFreeDB:(id)sender {
	NSDictionary*	fdb = [m_freeDB go];
	if (fdb != nil) {
		[m_progress startWithText:@"Update table data..."];
		[m_data updateWithFreeDBData:fdb];
		[self _allTo:FALSE]; // Filenames, don't apply
		
		if ([[m_patternField stringValue] length] > 0)
			[m_data allTagsToFilenamesForPattern:[m_patternField stringValue] withOpts:self shouldApply:FALSE];
		
		[m_progress stop];
		[m_fileTable reloadData];
	}
}

- (IBAction)showEditSelected:(id)sender {
	if ([m_fileTable numberOfSelectedRows] > 0) {
		// Enable all fields
		[m_editArtistCheck setState:NSOffState];
		[m_editAlbumCheck setState:NSOffState];
		[m_editYearCheck setState:NSOffState];
		[m_editGenreCheck  setState:NSOffState];
		
		// Copy values from the first selected row into the fields
		unsigned srow = [m_fileTable selectedRow];
		[m_editArtist setStringValue:[m_data stringForRow:srow andIdent:ArtistIdent]];
		[m_editAlbum setStringValue:[m_data stringForRow:srow andIdent:AlbumIdent]];
		[m_editYear setStringValue:[m_data stringForRow:srow andIdent:YearIdent]];
		[m_editGenre setStringValue:[m_data stringForRow:srow andIdent:GenreIdent]];		
			
	} else
		return; // something went wrong
	
	[NSApp beginSheet:m_editWin modalForWindow:m_mainWindow modalDelegate:self 
	   didEndSelector:@selector(editSelectedSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (void)editSelectedSheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode
					contextInfo:(void*)contextInfo {
    [m_editWin orderOut:self];
	
	if (returnCode == EDSEL_ACCEPT) {
		NSEnumerator*	en	= [m_fileTable selectedRowEnumerator]; // 10.2 compatible
		NSNumber*		ridx;
		unsigned		row;
		NSString*		art		= (([m_editArtistCheck state] == NSOnState) ? [m_editArtist stringValue] : nil),
						*alb	= (([m_editAlbumCheck state] == NSOnState) ? [m_editAlbum stringValue] : nil),
						*year	= (([m_editYearCheck state] == NSOnState) ? [m_editYear stringValue] : nil),
						*genre	= (([m_editGenreCheck state] == NSOnState) ? [m_editGenre stringValue] : nil);
				
		while (ridx = [en nextObject]) {
			row = [ridx unsignedIntValue];
			
			if (art != nil)
				[m_data setStringForRow:row andIdent:ArtistIdent toString:art];
			if (alb != nil)
				[m_data setStringForRow:row andIdent:AlbumIdent toString:alb];
			if (year != nil)
				[m_data setStringForRow:row andIdent:YearIdent toString:year];
			if (genre != nil)
				[m_data setStringForRow:row andIdent:GenreIdent toString:genre];
		}
		[m_fileTable reloadData];
	}
}

- (IBAction)autoNumberTrackNo:(id)sender {
	NSEnumerator*	en	= [m_fileTable selectedRowEnumerator]; // 10.2 compatible
	NSNumber*		ridx;
	unsigned		row;
	int				i = 1;
	
	while (ridx = [en nextObject]) {
		row = [ridx unsignedIntValue];
		[m_data setStringForRow:row andIdent:TrackNumberIdent toString:[NSString stringWithFormat:@"%d", i]];
		i++;
	}
	[m_fileTable reloadData];
}

#pragma mark - 
#pragma mark Options

- (BOOL)convertSpaceToUnderscore
{
	return (BOOL)([m_optToFilenameSpace state]  == NSOnState);
}

- (BOOL)convertDotToSpace
{
	return (BOOL)([m_optToTagDots state] == NSOnState);
}

- (BOOL)convertUnderscoreToSpace
{
	return (BOOL)([m_optToTagUnderscore state] == NSOnState);
}

- (BOOL)keepColumnDataIfEmpty 
{
	return (BOOL)([m_optToTagKeepData state] == NSOnState);
}

- (BOOL)sortIntoFolders
{
	return (BOOL)([m_optToFilenameFolders state] == NSOnState);
}

- (BOOL)generateV1Tag 
{
	return (BOOL)([m_optToTagV1Tag state] == NSOnState);
}

- (BOOL)padTag
{
	return (BOOL)([m_optToTagPadTag state] == NSOnState);
}

- (void)setOutDirectory:(NSString*)dir {
	if (m_outDir != nil) 
		[m_outDir release];
	m_outDir = [dir retain];
}

- (NSString*)outDirectory {
	return m_outDir;
}

#pragma mark -
#pragma mark Drop on dock icon and "open with..."

- (BOOL)application:(NSApplication*)theApplication openFile:(NSString*)filename {
	[self filesWereDropped:[NSArray arrayWithObject:filename]];
	return TRUE; // even when add fails
}

- (void)application:(NSApplication*)sender openFiles:(NSArray*)filenames { // 10.3+
	[self filesWereDropped:filenames];
}

#pragma mark -
#pragma mark Default values

- (BOOL)forceDefaultValues
{
	return (BOOL)([m_forceDefaults state] == NSOnState);
}

- (NSString*)defaultArtist
{
	return [m_defaultArtist stringValue];
}

- (NSString*)defaultAlbum
{
	return [m_defaultAlbum stringValue];
}

- (NSString*)defaultYear
{
	return [m_defaultYear stringValue];
}

- (NSString*)defaultGenre {
	return [m_defaultGenre stringValue];
}

#pragma mark -
#pragma mark Genre combo box source

- (int)numberOfItemsInComboBox:(NSComboBox*)cbox {
	return [m_genres count];
}

- (id)comboBox:(NSComboBox*)cbox objectValueForItemAtIndex:(int)index {
	return [m_genres objectAtIndex:index];
}

- (NSString*)comboBox:(NSComboBox*)cbox completedString:(NSString*)uncompletedString {
	int i;
	for (i = 0; i < [m_genres count]; i++)
		if ([[m_genres objectAtIndex:i] hasPrefix:uncompletedString])
			return [m_genres objectAtIndex:i];
	
	return uncompletedString;
}

- (unsigned int)comboBox:(NSComboBox*)cbox indexOfItemWithStringValue:(NSString*)string {
	return [m_genres indexOfObjectIdenticalTo:string];
}

#pragma mark -
#pragma mark Pattern builder methods

- (void)pbResetPartNo:(unsigned)no
{
	[m_pbFilename setTextColor:[NSColor textColor] range:m_pbParts[no]];	

	m_pbParts[no].length = 0;
}

- (void)pbResetAllParts
{
	int i;
	
	[m_pbFilename setTextColor:[NSColor textColor]];
	
	for (i = 0; i < PH_NUM_IDENTS; i++)
		m_pbParts[i].length = 0;
}

- (BOOL)pbAnyTextSelected
{
	NSRange r = [m_pbFilename selectedRange];	
	if (r.length == 0) {
		NSBeginAlertSheet(@"No selection", @"OK", nil, nil,
						  m_pbWindow, self, nil, nil, nil,
						  @"You must select a part of the filename first.");
		return FALSE;
	}
	return TRUE;
}

- (void)pbUpdatePartNo:(unsigned)no
{
	NSRange cr, tr;
	int		i;
	
	if (![self pbAnyTextSelected])
		return;
	
	cr = [m_pbFilename selectedRange];	
	
	// Remove old range
	if (m_pbParts[no].length > 0)
		[self pbResetPartNo:no];
	
	// Reset part if its range overlaps with the current range (= selection)
	for (i = 0; i < PH_NUM_IDENTS; i++) {
		tr = NSIntersectionRange(cr, m_pbParts[i]);
		if (tr.length > 0)
			[self pbResetPartNo:i];
	}
	
	// Store range
	m_pbParts[no] = cr;
	[m_pbFilename setTextColor:PBPartColors[no] range:cr];	
}

- (NSString*)pbGetNewPattern {
	NSMutableString*	np;
	unsigned			chrIdx;
	int					i, j;
	BOOL				skipPercent;
	int					spidx[PH_NUM_IDENTS];
	int					st;
	
	np = [NSMutableString stringWithString:[m_pbFilename string]];

	// The %% requires some special treatment
	chrIdx = 0;
	for (;;) {
		// Search for next '%'
		chrIdx = [np indexOfCharacter:(unichar)'%' startingAtIndex:chrIdx];
		if (chrIdx == NSNotFound)
			break;
	
		// Check if % is in a part - if so then ignore it
		skipPercent = FALSE; // <-- price for not using a 'GOTO'
		for (i = 0; i < PH_NUM_IDENTS; i++) {
			if (m_pbParts[i].length == 0)
				continue;
			if (NSLocationInRange(chrIdx, m_pbParts[i])) {
				skipPercent = TRUE;
				break;
			}
		}
		if (skipPercent) {
			chrIdx++;
			continue;
		}
		
		// Its not in any part range - shift all ranges where the location is > chrIdx
		for (i = 0; i < PH_NUM_IDENTS; i++) {
			if (m_pbParts[i].length == 0)
				continue;
			if (chrIdx < m_pbParts[i].location)
				m_pbParts[i].location++;
		}
		
		// % -> %%
		[np insertString:@"%" atIndex:chrIdx];
		chrIdx+=2;
	}
	
	// Now replace the ranges with the %c (sorting required)
	for (i = 0; i < PH_NUM_IDENTS; i++)
		spidx[i] = i;
	
	for (i = 0; i < PH_NUM_IDENTS-1; i++)
		for (j = 0; j < PH_NUM_IDENTS-1-i; j++)
			if (m_pbParts[spidx[j+1]].location > m_pbParts[spidx[j]].location) {
				st = spidx[j];
				spidx[j] = spidx[j+1];
				spidx[j+1] = st;
			}

	for (i = 0; i < PH_NUM_IDENTS; i++) {
		st = spidx[i];
		if (m_pbParts[st].length > 0)
			[np replaceCharactersInRange:m_pbParts[st]
							  withString:[NSString stringWithFormat:@"%%%c", [FFPlaceholders placeholderNo:st]]];
	}

	return [np retain];
}

/*
 *  IB Actions : pattern builder
 */
- (IBAction)pbDescriptionSelected:(id)sender
{
	[self pbUpdatePartNo:(unsigned)[[m_pbDescriptions selectedItem] tag]];
}

- (IBAction)pbResetAll:(id)sender
{
	[self pbResetAllParts];
}

- (IBAction)pbClose:(id)sender
{
	[NSApp endSheet:m_pbWindow returnCode:PB_DISCARD_PATTERN];
}

- (IBAction)pbCloseAndAdopt:(id)sender
{
	[NSApp endSheet:m_pbWindow returnCode:PB_ADOPT_PATTERN];	
}

#pragma mark -
#pragma mark Edit selected

- (void)fileTableSelectionDidChangeNotification:(NSNotification*)not {
	if ([m_fileTable numberOfSelectedRows] == 0) {
		[m_editButton setEnabled:FALSE];
		[m_editMenuItem setEnabled:FALSE];

		[m_autoTrackNumBtn setEnabled:FALSE];
	} else {
		[m_editButton setEnabled:TRUE];
		[m_editMenuItem setEnabled:TRUE];
		
		[m_autoTrackNumBtn setEnabled:TRUE];	
	} 
}

- (void)controlTextDidChange:(NSNotification*)not {
	id o = [not object];

	if (o == m_editArtist)
		[m_editArtistCheck setState:NSOnState];
	else if (o == m_editAlbum)
		[m_editAlbumCheck setState:NSOnState];
	else if (o == m_editYear)
		[m_editYearCheck setState:NSOnState];
	else if (o == m_editGenre)
		[m_editGenreCheck setState:NSOnState];
}

- (IBAction)editCancel:(id)sender {
	[NSApp endSheet:m_editWin returnCode:EDSEL_CANCEL];
}

- (IBAction)editAccept:(id)sender {
	[NSApp endSheet:m_editWin returnCode:EDSEL_ACCEPT];
}

#pragma mark -
#pragma mark Applescript

typedef enum {
	REPLACE_UNDERSCORE	= FOUR_CHAR_CODE('tund'),
	REPLACE_DOTS		= FOUR_CHAR_CODE('tdts'),
	KEEP_DATA			= FOUR_CHAR_CODE('tkdt'),
	GENERATE_V1_TAG		= FOUR_CHAR_CODE('tv1t'),
	PAD_TAG				= FOUR_CHAR_CODE('tpad'),
	REPLACE_SPACES		= FOUR_CHAR_CODE('fspc'),
	SORT_INTO_FOLDERS	= FOUR_CHAR_CODE('ffdr')
} OptionsCodes;

typedef enum {
	DV_ARTIST   = FOUR_CHAR_CODE('dart'),
	DV_ALBUM	= FOUR_CHAR_CODE('dalb'),
	DV_YEAR		= FOUR_CHAR_CODE('dyar'),
	DV_GENRE	= FOUR_CHAR_CODE('dgre')
} DefaultValueCodes;

typedef enum {
	COL_ARTIST		= FOUR_CHAR_CODE('cart'),
	COL_ALBUM		= FOUR_CHAR_CODE('calb'),
	COL_SONG_TITLE  = FOUR_CHAR_CODE('ctit'),
	COL_YEAR		= FOUR_CHAR_CODE('cyar')	
} ColumnCodes;

- (void)_changeOptionWithScriptArguments:(NSDictionary*)earg {
	int state   = [[earg objectForKey:@"checked"] intValue];
	
	switch ([[earg objectForKey:@"name"] intValue]) {
		#define CASE_SET_STATE(OPT, MVAR) \
			case OPT : \
				[(MVAR) setState:state]; \
				break;
		
		CASE_SET_STATE(REPLACE_UNDERSCORE, m_optToTagUnderscore)
		CASE_SET_STATE(REPLACE_DOTS, m_optToTagDots)
		CASE_SET_STATE(KEEP_DATA, m_optToTagKeepData)
		CASE_SET_STATE(GENERATE_V1_TAG, m_optToTagV1Tag)
		CASE_SET_STATE(PAD_TAG, m_optToTagPadTag)
		CASE_SET_STATE(REPLACE_SPACES, m_optToFilenameSpace)
		CASE_SET_STATE(SORT_INTO_FOLDERS, m_optToFilenameFolders)
	}
}

- (void)_changeMode:(int)modeCode {
	if (modeCode == FOUR_CHAR_CODE('mftt'))
		[m_mode selectItemAtIndex:0]; // HARDCODED !
	else
		[m_mode selectItemAtIndex:1];
	
	[self modeChanged:self];
}

- (void)_changeDefaultValueWithScriptArgument:(NSDictionary*)earg {
	NSString*   value   = [earg objectForKey:@"value"];
	
	switch ([[earg objectForKey:@"name"] intValue]) {
		#define CASE_SET_VALUE(OPT, MVAR) \
			case OPT : \
				[(MVAR) setStringValue:value]; \
				break;
		
		CASE_SET_VALUE(DV_ARTIST, m_defaultArtist)
		CASE_SET_VALUE(DV_ALBUM, m_defaultAlbum)
		CASE_SET_VALUE(DV_YEAR, m_defaultYear)
		CASE_SET_VALUE(DV_GENRE, m_defaultGenre)
	}
}

- (void)_changeTrackWithScriptArgument:(NSDictionary*)earg {	
	[m_data setTrackWithNo:[[earg objectForKey:@"trackno"] intValue]
				  toArtist:[earg objectForKey:@"artist"]
					 album:[earg objectForKey:@"album"]
				trackTitle:[earg objectForKey:@"tracktitle"]
				   andYear:[earg objectForKey:@"year"]];
	
	if ([[earg objectForKey:@"reload"] isEqualToString:@"true"])
		[m_fileTable reloadData];	
}

- (void)scriptCommandReceived:(NSNotification*)not {
	switch ([[[not object] commandDescription] appleEventCode]) {
		case FOUR_CHAR_CODE('addf') :
			[self filesWereDropped:[NSArray arrayWithObject:[[not object] directParameter]]];
			break;
		case FOUR_CHAR_CODE('clrl') :
			[self clearList:self];
			break;
		case FOUR_CHAR_CODE('spat') :
			[m_patternField setStringValue:[[not object] directParameter]];
			break;
		case FOUR_CHAR_CODE('odir') :
			[self setOutDirectory:[[[not object] directParameter] stringByStandardizingPath]];
			break;
		case FOUR_CHAR_CODE('mode') :
			[self _changeMode:[[[not object] directParameter] intValue]];
			break;
		case FOUR_CHAR_CODE('sopt') :
			[self _changeOptionWithScriptArguments:[[not object] evaluatedArguments]];
			break;
		case FOUR_CHAR_CODE('fdvl') :
			[m_forceDefaults setState:[[[not object] directParameter] intValue]];
			break;
		case FOUR_CHAR_CODE('dval') :
			[self _changeDefaultValueWithScriptArgument:[[not object] evaluatedArguments]];
			break;
		case FOUR_CHAR_CODE('trck') :
			[self _changeTrackWithScriptArgument:[[not object] evaluatedArguments]];
			break;
		case FOUR_CHAR_CODE('reld') :
			[m_fileTable reloadData];
			break;
		case FOUR_CHAR_CODE('appl') :
			[self apply:self];
			break;
	}
}

@end
