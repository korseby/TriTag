RCS_ID("$Id: FFPreferences.m 243 2004-08-12 18:14:36Z ravemax $")

#import "FFPreferences.h"

@implementation FFPreferences

static NSString*	SearchURLKey		= @"search_url";
static NSString*	ResultPatternKey	= @"result_pattern";
static NSString*	YearPatternKey		= @"year_pattern";
static NSString*	TrackPatternKey		= @"track_pattern";

#pragma mark -
#pragma mark Init and cleanup

- (id)init {
	self = [super init];
	if (self != nil) {
		NSUserDefaults*	ud = [NSUserDefaults standardUserDefaults];
		
		[ud registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
			@"http://www.freedb.org/freedb_search.php?allfields=NO&fields=artist&fields=title&allcats=YES&grouping=none&words=",
				SearchURLKey,
			@"<tr><td><a href=\"([^\"]+)\">\\s*(.+?) \\/ ([^<]+)",
				ResultPatternKey,
			@"year:\\s+(\\d{2,4})",
				YearPatternKey,
			@"<tr><td valign=top>\\s*(\\d+)\\.<\\/td><td valign=top>\\s+([^<]+)<\\/td><td><b>([^<]+)",
				TrackPatternKey,
			nil]];
		
		m_freeDBSearchURL	= [[ud stringForKey:SearchURLKey] retain];
		m_resultPattern		= [[ud stringForKey:ResultPatternKey] retain];
		m_yearPattern		= [[ud stringForKey:YearPatternKey] retain];
		m_trackPattern		= [[ud stringForKey:TrackPatternKey] retain];
	}
	return self;
}

- (void)dealloc {
	[m_freeDBSearchURL release];
	[m_resultPattern release];
	[m_yearPattern release];
	[m_trackPattern release];

	[super dealloc];
}

#pragma mark -
#pragma mark Getters

- (NSString*)freeDBSearchURL	{ return m_freeDBSearchURL; }
- (NSString*)resultPattern		{ return m_resultPattern; }  // url, artist, album
- (NSString*)yearPattern		{ return m_yearPattern;	}
- (NSString*)trackPattern		{ return m_trackPattern; } // no duration, title

@end
