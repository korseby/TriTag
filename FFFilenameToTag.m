RCS_ID("$Id: FFFilenameToTag.m 264 2004-08-20 14:22:11Z ravemax $")

#import "FFFilenameToTag.h"
#import "FFController.h"
#import "FFPlaceholders.h"

//#import <pcre.h>

@implementation FFFilenameToTag

- (void)_extractSeperatorsFromString:(NSString*)pstr
{
	unsigned	i;
	unsigned	prevPos, pos;
	
	prevPos = [m_ph positionAtIndex:0];
	if (prevPos > 0)
		m_sepBefore = [[pstr substringToIndex:prevPos] retain];
	else
		m_sepBefore = nil;
	
	prevPos += 2;
	m_sepBetween = [[NSMutableArray alloc] initWithCapacity:[m_ph numberOfUsedIdents]-1];
	for (i = 1; i < [m_ph numberOfUsedIdents]; i++) {
		pos  = [m_ph positionAtIndex:i];
		[m_sepBetween addObject:[pstr substringWithRange:NSMakeRange(prevPos, pos-prevPos)]];	
		prevPos = pos+2;
	}
	
	if (prevPos < [pstr length])
		m_sepAfter = [pstr substringFromIndex:prevPos];
	else
		m_sepAfter = nil;
}

- (id)initWithString:(NSString*)pstr withOpts:(id)optObj
{	
	if (self = [super init]) {
		m_ph = [[FFPlaceholders alloc] initWithString:pstr];
		if (m_ph == nil)
			return nil;
		
		[self _extractSeperatorsFromString:[m_ph getString]];
		
		m_optObj = optObj;
	}
	return self;
}

- (void)dealloc
{
	[m_ph release];

	[m_sepBefore release];
	[m_sepAfter release];
	[m_sepBetween release];
	
	[super dealloc];
}

- (NSDictionary*)tagFromFilename:(NSString*)fname
{
	NSString*			stFname, *ident, *partStr;
	unsigned			i;
	unsigned			searchStart;
	NSRange				sepRange, partRange[PH_NUM_IDENTS];
	NSMutableString*	stFnameOpt;
	NSMutableDictionary*	partDict;
	
	// 1. Prefix and suffix available ?
	if (((m_sepBefore != nil) && ![fname hasPrefix:m_sepBefore]) ||
	 ((m_sepAfter != nil) && ![fname hasSuffix:m_sepAfter])) {
		NSBeep();
/*		NSBeginAlertSheet(@"Separator problem", @"Skip left files", nil, nil,
						  [NSApp mainWindow], self, nil, nil, nil,
						  @"Start- or endseparator not found - correct your filename pattern");
*/
		return nil;
	}
	stFname = [fname substringWithRange:NSMakeRange([m_sepBefore length], [fname length] - ([m_sepAfter length] + [m_sepBefore length]))];
		
	// 2. Search "between" separators
	searchStart = 0;
	for (i = 0; i < [m_sepBetween count]; i++) {
		sepRange = [stFname rangeOfString:[m_sepBetween objectAtIndex:i] options:0 range:
			NSMakeRange(searchStart, [stFname length] - searchStart)];
		if (sepRange.location == NSNotFound) {
			NSBeep();
/*			NSBeginAlertSheet(@"Separator problem", @"Skip left files", nil, nil,
							  [NSApp mainWindow], self, nil, nil, nil,
							  @"Separators not found - correct your filename pattern");
*/
			return nil;
		}
		partRange[i] = NSMakeRange(searchStart, sepRange.location - searchStart);
		searchStart = sepRange.location+sepRange.length;
	}
	partRange[i] = NSMakeRange(searchStart, [stFname length] - searchStart);
	
	// 3. Option handling
	if ([m_optObj convertUnderscoreToSpace] || [m_optObj convertDotToSpace]) {
		stFnameOpt = [NSMutableString stringWithString:stFname];
		
		if ([m_optObj convertUnderscoreToSpace])
			[stFnameOpt replaceOccurrencesOfString:@"_" withString:@" " options:0 range:NSMakeRange(0, [stFnameOpt length])];
		if ([m_optObj convertDotToSpace])
			[stFnameOpt replaceOccurrencesOfString:@"." withString:@" " options:0 range:NSMakeRange(0, [stFnameOpt length])];
	} else
		stFnameOpt = (NSMutableString*)stFname; // upcasting
	
	// 4. Create new dict with
	partDict = [NSMutableDictionary dictionaryWithCapacity:[m_ph numberOfUsedIdents]];
	for (i = 0; i <  [m_ph numberOfUsedIdents]; i++) {
		ident = [m_ph identAtIndex:i];
		partStr = [stFnameOpt substringWithRange:partRange[i]];

		if ([ident isEqualTo:TrackNumberIdent]  && ([partStr characterAtIndex:0] == '0'))
			partStr = [partStr substringFromIndex:1];
				
		[partDict setObject:partStr forKey:ident];
	}

	return partDict;
}

/*-------------------------------------------------------------------------
 *	Unused code !
 *  PCRE has a index bug when unicode is used#
 * 
 */

#if 0

#define NUM_CHARS_ESCAPED 14
static NSString* CharsToBeEscaped[NUM_CHARS_ESCAPED] = {
	@"\\", // must be the first !
	@"[", @"]", @"(", @")", @"{", @"}",
	@"*", @"+", @"?",
	@"^", @"$", @"|",
	@"."
};

static NSString* NumberPattern	= @"(\\d+)";
static NSString* YearPattern	= @"(\\d+)";
static NSString* StringPattern	= @"(.+)"; // greedy mode noetig ?

- (NSString*)_createRExpressionFromString:(NSString*)pstr
{
	NSMutableString*	tmpStr;
	int					i;
	NSString*			ident, *usePattern;

//	NSLog(@"pstr: %@", pstr);
	tmpStr = [NSMutableString stringWithString:pstr];
	
	// 1. Escape special characters
	for (i = 0; i < NUM_CHARS_ESCAPED; i++) {
		[tmpStr replaceOccurrencesOfString:CharsToBeEscaped[i] withString:[NSString stringWithFormat:@"\\%@", CharsToBeEscaped[i]] options:0 range:NSMakeRange(0, [tmpStr length])];
	}	
//	NSLog(@"tmpStr(1): %@\n", tmpStr);
	
	// 2. Placeholder order and replacment
	m_ph = [[FFPlaceholders alloc] initWithString:pstr];
	for (i = [m_ph numberOfUsedIdents]-1; i >= 0; i--) {
		ident = [m_ph identAtIndex:i];
		if ([ident isEqualToString:TrackNumberIdent])
			usePattern = NumberPattern;
		else if ([ident isEqualToString:YearIdent])
			usePattern = YearPattern;
		else
			usePattern = StringPattern;
			
		[tmpStr replaceCharactersInRange:NSMakeRange([m_ph positionAtIndex:i], 2) withString:usePattern];
	}
//	NSLog(@"tmpStr(2): %@\n", tmpStr);
	
	return [NSString stringWithFormat:@"%@", tmpStr];
//	return [NSString stringWithFormat:@"%@", tmpStr];
}

- (BOOL)_compileRExpressionWithString:(NSString*)reStr
{
	const char* errMsg;
	int			errOfs;
	
	NSLog(@"'%@'", reStr);
	m_cre = pcre_compile([reStr UTF8String], PCRE_UTF8 | PCRE_CASELESS, &errMsg, &errOfs, NULL);
	if (m_cre == NULL) {
		NSLog(@"pcre failed: %s - ofs %d\n", errMsg, errOfs);
		return FALSE;
	}
	return TRUE;
}

- (void)_extractSeperatorsFromString:(NSString*)pstr
{
	unsigned	i;
	unsigned	prevPos, pos;
	
//	m_ph = [[FFPlaceholders alloc] initWithString:pstr];
	prevPos = [m_ph positionAtIndex:0];
	if (prevPos > 0) {
		NSLog(@"before 1st.placeholder: %@", [pstr substringToIndex:prevPos]);
	} else
		NSLog(@"before 1st.placeholde: empty");
	
	prevPos += 2;

	for (i = 1; i < [m_ph numberOfUsedIdents]; i++) {
		pos  = [m_ph positionAtIndex:i];
		NSLog(@"%d = '%@'", i, [pstr substringWithRange:NSMakeRange(prevPos, pos-prevPos)]);
		prevPos = pos+2;
	}
	
	NSLog(@"%u, %u", prevPos, [pstr length]);
	if (prevPos < [pstr length])
		NSLog(@"%after.last.ph: %@", [pstr substringFromIndex:prevPos]);
	
	
}

- (id)initWithString:(NSString*)pstr withOpts:(id)optObj
{	
	if (self = [super init]) {
		NSString* reStr = [self _createRExpressionFromString:pstr];
		if (![self _compileRExpressionWithString:reStr])
			return nil;

		[self _extractSeperatorsFromString:pstr];

			
		m_optObj = optObj;
	}
	return self;
}

- (void)dealloc
{
	[m_ph release];
	free(m_cre);
	
	[super dealloc];
}

- (NSDictionary*)tagFromFilename:(NSString*)fname
{
	#define NUM_VECT ((NUM_PH_IDENTS+1)*3)
	int 					ovector[NUM_VECT];
	int						matches;
	NSMutableString*		fnameMod;
	int 					i;
	NSString*				ident, *str;
	NSMutableDictionary*	subDict;

	char** substr;
	int rc;
	
	// 1. Match or not
	NSLog(@"%@", fname);
	
	matches = pcre_exec(m_cre, NULL, [fname UTF8String], [fname length], 0, 0, ovector, NUM_VECT);	
	if (matches < 0) {
		if (matches == PCRE_ERROR_NOMATCH)
			NSLog(@"no match");
		else
			NSLog(@"pcre_exec failure: %d\n", matches);
		return nil;
	}
	if ((matches == 0) || ([m_ph numberOfUsedIdents]+1 != matches)) {
		NSLog(@"not enough output vectors - this should never(!) happen");
		return nil;
	}
	
	// 2. Options handling
	fnameMod = [NSMutableString stringWithString:fname];
	if ([m_optObj convertUnderscoreToSpace])
		[fnameMod replaceOccurrencesOfString:@"_" withString:@" " options:0 range:NSMakeRange(0, [fnameMod length])];
	
	// 3. Create new dict with the substrings
	subDict = [NSMutableDictionary dictionaryWithCapacity:matches-1];
	matches <<= 1;
	for (i = 2; i < matches; i+= 2) {
		ident = [m_ph identAtIndex:((i >> 1)-1)];
		NSLog(@"%d = %d, %d", i, ovector[i], ovector[i+1]);
		str = [fnameMod substringWithRange:NSMakeRange(ovector[i], ovector[i+1]-ovector[i])];
		
		if ([ident isEqualTo:TrackNumberIdent] && ([str characterAtIndex:0] == '0'))
			str = [str substringFromIndex:1];
		
		[subDict setObject:str forKey:ident];
	}
	

	return subDict;
}

#endif 


@end
