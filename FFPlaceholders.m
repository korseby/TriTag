RCS_ID("$Id: FFPlaceholders.m 234 2004-07-31 13:55:31Z ravemax $")

#import "FFPlaceholders.h"

NSString* ArtistIdent		= @"Artist";
NSString* AlbumIdent		= @"Album";
NSString* TrackNumberIdent	= @"TrackNumber";
NSString* TrackTitleIdent	= @"TrackTitle";
NSString* YearIdent			= @"Year";
NSString* GenreIdent		= @"Genre";

@implementation FFPlaceholders

static struct {
	char		ichr;
	NSString*	ident;
} IdentCharacterMap[PH_NUM_IDENTS] = {
	{ 'a', nil },
	{ 't', nil },
	{ 'n', nil },
	{ 's', nil },
	{ 'y', nil },
	{ 'g', nil }
};


+ (char)placeholderNo:(unsigned)no 
{
	if (no >= PH_NUM_IDENTS)
		return '*';
	return IdentCharacterMap[no].ichr;
}

+ (void)initialize
{
	IdentCharacterMap[PH_ARTIST].ident			= ArtistIdent;
	IdentCharacterMap[PH_ALBUM].ident			= AlbumIdent;
	IdentCharacterMap[PH_TRACK_NUMBER].ident	= TrackNumberIdent;
	IdentCharacterMap[PH_TRACK_TITLE].ident		= TrackTitleIdent;
	IdentCharacterMap[PH_YEAR].ident			= YearIdent;
	IdentCharacterMap[PH_GENRE].ident			= GenreIdent;
}

- (NSString*)_indentForChar:(char)chr
{
	int i;

	for (i = 0; i < PH_NUM_IDENTS; i++) {
		if (IdentCharacterMap[i].ichr == chr)
			return IdentCharacterMap[i].ident;
	}
	
	NSBeginAlertSheet(@"Pattern error", @"Stop processing", nil, nil,
					  [NSApp mainWindow], self, nil, nil, nil,
					  @"The placeholder '%c' is unknown", chr);	
	return nil;
}

- (BOOL)_identOrderFromString:(NSString*)str
{
	unsigned	i = 0;
	NSString*   ident;
	
	m_num = 0;
	m_str = [NSMutableString stringWithString:str];
	while (i < [m_str length]) {
		if ([m_str characterAtIndex:i] == '%') {
			
			// No characters after %
			if ((i+1 == [m_str length]) || ([m_str characterAtIndex:i+1] == '.')) {
				NSBeginAlertSheet(@"Pattern error", @"Stop processing", nil, nil,
								  [NSApp mainWindow], self, nil, nil, nil,
								  @"Expected another character after the last '%%'.");
				return FALSE;
			}
			
			// A real %
			if ([m_str characterAtIndex:i+1] == '%') {
				[m_str deleteCharactersInRange:NSMakeRange(i, 1)];
				i++;
			
			// Placeholder
			} else {
				// Already PH_NUM idents ?
				if (m_num == PH_NUM_IDENTS) {
					NSBeginAlertSheet(@"Pattern error", @"Stop processing", nil, nil,
									  [NSApp mainWindow], self, nil, nil, nil,
									  @"The pattern is invalid - to many placeholders");				
					return FALSE;
				}
				
				// char -> ident
				ident = [self _indentForChar:(char)[m_str characterAtIndex:i+1]];
				if (ident == nil)
					return FALSE;
				
				m_phs[m_num].ident = ident;
				m_phs[m_num].pos = i;
				m_num++;
				i += 2;
			}
			
		// Just a normal character
		} else
			i++;
	}
	
	return TRUE;
}

- (id)initWithString:(NSString*)str
{	
	if (self = [super init]) {
		if (![self _identOrderFromString:str])
			return nil;
	}
	return self;
}

- (NSMutableString*)getString
{
	return m_str;
}

- (unsigned)numberOfUsedIdents
{
	return m_num;
}

- (NSString*)identAtIndex:(unsigned)idx
{
	if (idx >= m_num)
		return nil;
	
	return m_phs[idx].ident;
}

- (unsigned)positionAtIndex:(unsigned)idx
{
	if (idx >= m_num)
		return (unsigned)-1;
	
	return m_phs[idx].pos;
}

@end
