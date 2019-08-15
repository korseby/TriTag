RCS_ID("$Id: FFTagToFilename.m 264 2004-08-20 14:22:11Z ravemax $")

#import "FFTagToFilename.h"
#import "FFController.h"
#import "FFData.h"
#import "FFPlaceholders.h"

@implementation FFTagToFilename

- (id)initWithPattern:(NSString*)patStr andOpts:(id)optObj
{
	if (self = [super init]) {
		m_patStr = [patStr retain];
		m_optObj = [optObj retain];

		m_emptyTagAction = ASK_DIALOG;
	}
	return self;
}

- (void)dealloc
{
	[m_patStr release];
	[m_optObj release];
	
	[super dealloc];
}

- (NSString*)filenameFromTag:(NSDictionary*)row
{
	FFPlaceholders* 	ph;
	NSMutableString*	fname;
	BOOL				allEmpty = TRUE;
	int					i;
	NSString*			ident, *str;

	ph = [[FFPlaceholders alloc] initWithString:m_patStr];
	if (ph == nil) {
		return nil;
	}
	if ([ph numberOfUsedIdents] == 0) {
		[ph release];
		NSBeginAlertSheet(@"Pattern error", @"Skip file", nil, nil,
						  [NSApp mainWindow], self, nil, nil, nil,
						  @"No placeholders specified");
		return nil;
	}

	// Replace placeholders with tag content
	fname = [NSMutableString stringWithString:[ph getString]];
	i = (int)[ph numberOfUsedIdents]-1;
	for (; i >= 0; i--) {
		ident = [ph identAtIndex:i];
		str = [row objectForKey:ident];
		if ([str length] > 0) {
			allEmpty = FALSE;
			if ([ident isEqualTo:TrackNumberIdent])
				str = [NSString stringWithFormat:@"%02d", [str intValue]];
		}
		[fname replaceCharactersInRange:NSMakeRange([ph positionAtIndex:i], 2) withString:str];
	}
	[ph release];
	
	if (allEmpty) {
		EmptyTagAction eta;
		
		if (m_emptyTagAction == ASK_DIALOG) {
			int ret = NSRunAlertPanel(@"Tag empty", @"All tags are empty for the given pattern. Do you want to keep the original filename ?", @"Keep", @"Keep for remaining files", @"Skip");
	
			if (ret == 0) // Keep remaining
				m_emptyTagAction = KEEP_ORG_NAME;
			
			eta = (ret == -1) ? RETURN_EMPTY : KEEP_ORG_NAME;
		} else
			eta = m_emptyTagAction;
		
		if (eta == KEEP_ORG_NAME)
			return [[row objectForKey:@"Filepath"] lastPathComponent];

		return nil;
	}
	
	// Misc reformat
	fname = [[FFTagToFilename replaceInvalidCharacters:fname] retain];

	// 
	if ([fname length] > 250) // for strange tooo long tags
		fname = [NSMutableString stringWithString:[fname substringToIndex:250]];

	if ([m_optObj convertSpaceToUnderscore]) 
		[fname replaceOccurrencesOfString:@" " withString:@"_" options:0 range:NSMakeRange(0, [fname length])];
	else
		return [fname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];


	return [NSString stringWithString:fname];
}

+ (NSMutableString*)replaceInvalidCharacters:(NSString*)fname
{
	NSMutableString*	vdname;
	
	vdname = [NSMutableString stringWithString:fname];
	
	[vdname replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, [vdname length])];
	[vdname replaceOccurrencesOfString:@"\\" withString:@"_" options:0 range:NSMakeRange(0, [vdname length])];
	[vdname replaceOccurrencesOfString:@":" withString:@"-" options:0 range:NSMakeRange(0, [vdname length])];
	[vdname replaceOccurrencesOfString:@"?" withString:@"-" options:0 range:NSMakeRange(0, [vdname length])];
	[vdname replaceOccurrencesOfString:@"*" withString:@"X" options:0 range:NSMakeRange(0, [vdname length])];
	[vdname replaceOccurrencesOfString:@"\"" withString:@" " options:0 range:NSMakeRange(0, [vdname length])];
//	[vdname replaceOccurrencesOfString:@"'" withString:@"" options:0 range:NSMakeRange(0, [vdname length])];
	
	return vdname;
}


@end
