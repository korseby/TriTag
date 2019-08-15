RCS_ID("$Id: FFFreeDB.m 259 2004-08-18 12:26:05Z ravemax $")

#if 0 // Disabled for now ....

#import "FFFreeDB.h"
#import "FFPreferences.h"
#import "FFProgress.h"
#import <AGRegex/AGRegex.h>

@implementation FFFreeDB

static	NSString*	FDBURLIdent			= @"url";
		NSString*	FDBArtistIdent		= @"artist";
		NSString*	FDBAlbumIdent		= @"album";
		NSString*	FDBYearIdent		= @"year";
		NSString*	FDBTracksIdent		= @"tracks";
		NSString*	FDBTrackNoIdent		= @"track_no";
		NSString*	FDBDurationIdent	= @"duration";
		NSString*	FDBTrackTitleIdent	= @"track_title";

#define SEARCH_ELEMENT_URL		1
#define SEARCH_ELEMENT_ARTIST	2
#define SEARCH_ELEMENT_ALBUM	3

#define TRACK_ELEMENT_NO		1
#define TRACK_ELEMENT_DURATION	2
#define TRACK_ELEMENT_TITLE		3

#define YEAR_ELEMENT			1

- (id)init {
	self = [super init];
	if (self != nil) {
		m_albums	= [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[m_albums release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark IB Actions

#define HIDE_SHEET(SHEET) \
	[NSApp endSheet:SHEET]; \
	[SHEET orderOut:NULL];

#define BTN_CANCEL		-1
#define BTN_SEARCH		1
#define BTN_SHOW_RES	2

- (IBAction)cancel:(id)sender {
	[NSApp stopModalWithCode:BTN_CANCEL];
}

- (IBAction)search:(id)sender {
	[NSApp stopModalWithCode:BTN_SEARCH];	
}

- (IBAction)acceptSelection:(id)sender {
	[NSApp stopModalWithCode:[m_albumsTable selectedRow]];
}

- (IBAction)showPrevResults:(id)sender {
	[NSApp stopModalWithCode:BTN_SHOW_RES];	
}

#pragma mark -

- (NSString*)_fetchURLWithString:(NSString*)url andTitle:(NSString*)title {
	[m_progress startWithText:[NSString stringWithFormat:@"Fetching %@...", title]];
	
//	NSString* txt = [NSString stringWithContentsOfFile:url];
	NSString* txt = [NSString stringWithContentsOfURL:[NSURL URLWithString:url]];
	
	[m_progress stop];
	
	if (txt == nil)
		NSRunAlertPanel(@"Network problems", @"Failed to fetch the %@ page",
						@"OK", nil, nil,
						title);	
	return txt;
}

- (BOOL)_getAlbums:(NSString*)searchKeywords {
	// Create search URL
	NSMutableString* skw = [NSMutableString stringWithString:searchKeywords];
	[skw replaceOccurrencesOfString:@" " withString:@"+" options:0 range:NSMakeRange(0, [skw length])];
	NSString* urlStr = [[m_prefs freeDBSearchURL] stringByAppendingString:skw];	
	
	//
//	NSString* resultPage = [self _fetchURLWithString:@"/Users/ravemax/Projects/Cocoa/TriTag/freedb/freedb-pete-crash.html" andTitle:@"result"];
	NSString* resultPage = [self _fetchURLWithString:urlStr andTitle:@"result"];
	
	if (resultPage == nil)
		return FALSE;
	
	// Parse HTML
	[m_progress startWithText:@"Parsing result page"];
	
	AGRegex*		resultRE	= [AGRegex regexWithPattern:[m_prefs resultPattern]];
	NSEnumerator*	resEn		= [resultRE findEnumeratorInString:resultPage];
	AGRegexMatch*	resMatch	= nil;
	int				found		= 0;
	
	[m_albums removeAllObjects];
	while (resMatch = [resEn nextObject]) {
		[m_albums addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[resMatch groupAtIndex:SEARCH_ELEMENT_URL], FDBURLIdent,
			[resMatch groupAtIndex:SEARCH_ELEMENT_ARTIST], FDBArtistIdent,
			[resMatch groupAtIndex:SEARCH_ELEMENT_ALBUM], FDBAlbumIdent,
			nil]];

		found++;
		if (found == FREEDB_MAX_MATCHES) {
			NSRunInformationalAlertPanel(@"No many matches", @"TriTag now only shows the first %d matches. Try to specify more precise search keywords next time.",
										 @"OK", nil, nil,
										 FREEDB_MAX_MATCHES);
			break;
		}
	}
	[m_progress stop];

	return TRUE;
}

- (NSNumber*)_durationInSecondsFromString:(NSString*)dstr {
	int	sec;
	
	if ([dstr length] < 4)
		sec	= 0;
	else {
		sec	= [dstr intValue]*60;
		sec += [[dstr substringFromIndex:([dstr length]-2)] intValue];
	}

	return [NSNumber numberWithInt:sec];
}

- (NSMutableArray*)_getTracks:(NSString*)url andYear:(NSString**)year {
//	NSString* tracksPage = [self _fetchURLWithString:@"/Users/ravemax/Projects/Cocoa/TriTag/freedb/freedb-ozomatli-tracks.html" andTitle:@"details"];
	NSString* tracksPage = [self _fetchURLWithString:url andTitle:@"details"];
	if (tracksPage == nil)
		return nil;
	
	// Year
	AGRegex*		yrRE	= [AGRegex regexWithPattern:[m_prefs yearPattern]];
	AGRegexMatch*	yrMatch	= [yrRE findInString:tracksPage];
	
	*year	= (yrMatch == nil) ? @"" : [yrMatch groupAtIndex:YEAR_ELEMENT];
	
	// Every track
	NSMutableArray*	tracks	= [NSMutableArray array];
	AGRegex*		trRE	= [AGRegex regexWithPattern:[m_prefs trackPattern]];
	NSEnumerator*	trEn	= [trRE findEnumeratorInString:tracksPage];
	AGRegexMatch*	trMatch;
	
	while (trMatch = [trEn nextObject]) {
		[tracks addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[trMatch groupAtIndex:TRACK_ELEMENT_NO], FDBTrackNoIdent,
			[self _durationInSecondsFromString:[trMatch groupAtIndex:TRACK_ELEMENT_DURATION]], FDBDurationIdent,
			[trMatch groupAtIndex:TRACK_ELEMENT_TITLE], FDBTrackTitleIdent,
			nil]];		
	}
	
	return tracks;
}

#pragma mark -

- (NSDictionary*)go {
	// Search sheet
	NSString*	skeywords;
	int			ret;
	
	
	// Disable "show res" button if no results
	if ([m_albums count] < 2)
		[m_showPrevResBtn setHidden:TRUE];
	else
		[m_showPrevResBtn setHidden:FALSE];
	
	// Get Keywords
	do {
		[NSApp beginSheet:m_searchWin modalForWindow:m_mainWin modalDelegate:self
		   didEndSelector:nil contextInfo:NULL];
		
		ret = [NSApp runModalForWindow:m_searchWin];
		if (ret == BTN_CANCEL) {
			HIDE_SHEET(m_searchWin);
			return nil;
		}
		if (ret == BTN_SHOW_RES) // No need for keywords
			break;
		
		// Something entered ?
		skeywords = [m_searchText stringValue];
		if ([skeywords length] == 0)
			NSRunInformationalAlertPanel(@"No keywords", @"Please enter some keywords before clicking 'Search'",
										 @"OK", nil, nil);			
	} while ([skeywords length] == 0);

	HIDE_SHEET(m_searchWin);

	// Get albums from FreeDB
	if (ret == BTN_SEARCH) {
		if ([self _getAlbums:skeywords] == FALSE)
			return nil;
	
		if ([m_albums count] == 0) {
			NSRunInformationalAlertPanel(@"Nothing found", @"Nothing matched your keywords.",
									 @"OK", nil, nil);
			return nil;
		}
	}
	
	// Albums sheet
	int salb;
	if ([m_albums count] == 1)
		salb = 0;
	else {
		[NSApp beginSheet:m_albumsWin modalForWindow:m_mainWin modalDelegate:self didEndSelector:nil contextInfo:NULL];
		[m_albumsTable reloadData];
		salb = [NSApp runModalForWindow:m_albumsWin];
		HIDE_SHEET(m_albumsWin);
	}
	
	// Tracks
	NSString*		year;
	NSMutableArray*	tracks = [self _getTracks:[[m_albums objectAtIndex:salb] 
								objectForKey:FDBURLIdent] andYear:&year];
	if (tracks == nil)
		return nil;
	
	// Return the freedb entry dict
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[[m_albums objectAtIndex:salb] objectForKey:FDBArtistIdent], FDBArtistIdent,
		[[m_albums objectAtIndex:salb] objectForKey:FDBAlbumIdent], FDBAlbumIdent,
		year, FDBYearIdent,
		tracks, FDBTracksIdent,
		nil];
}
	
#pragma mark -
#pragma mark Albums table data source

- (int)numberOfRowsInTableView:(NSTableView*)tv {
	return [m_albums count];
}

- (id)tableView:(NSTableView*)tv objectValueForTableColumn:(NSTableColumn*)col row:(int)rowIndex {
	return [[m_albums objectAtIndex:rowIndex] objectForKey:[col identifier]];
 
}

@end

#endif