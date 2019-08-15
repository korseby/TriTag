RCS_ID("$Id: FFFavPatterns.m 243 2004-08-12 18:14:36Z ravemax $")

#import "FFFavPatterns.h"

@implementation FFFavPatterns

static NSString*	FavPatternKey	= @"fav_patterns";

#define UD [NSUserDefaults standardUserDefaults]

- (void)_patternsToMenu {
	int	i;

	for (i = 0; i < [m_patterns count]; i++) {
		[[m_patternsMenu insertItemWithTitle:[m_patterns objectAtIndex:i]
									  action:@selector(_patternItemAction:) 
							   keyEquivalent:@""
									 atIndex:i] setTarget:self];
	}
	
	[m_patternTable reloadData];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		// Read existing patterns and update menu
		m_patterns	= [[NSMutableArray alloc] init];
		NSArray*	sp = [UD stringArrayForKey:FavPatternKey];
		if (sp != nil)
			[m_patterns addObjectsFromArray:sp];
		
		// Register for app termination
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appWillTerminate:) name:NSApplicationWillTerminateNotification object:NSApp];
	}
	return self;
}

- (void)awakeFromNib {
	[self _patternsToMenu];	
}

- (void)dealloc {
	[m_patterns release];
	[super dealloc];
}

- (void)_appWillTerminate:(NSNotification*)not {
	[UD setObject:m_patterns forKey:FavPatternKey];
}


#pragma mark -
#pragma mark IB actions

- (IBAction)addCurrentPattern:(id)sender {
	NSString*	pat = [m_patternField stringValue];
	
	if ([pat length] > 0) {
		[[m_patternsMenu insertItemWithTitle:pat action:@selector(_patternItemAction:) 
									  keyEquivalent:@"" atIndex:[m_patterns count]] setTarget:self];
		[m_patterns addObject:pat];
		[m_patternTable reloadData];
	} else
		NSRunAlertPanel(@"Pattern length is 0", @"Enter a pattern before trying to add it ;-)",
						@"OK", nil, nil);
}

- (IBAction)editPatterns:(id)sender {
	[m_win makeKeyAndOrderFront:self];
}

- (BOOL)_selectionCheck {
	if ([m_patternTable	selectedRow] == -1) {
		NSRunAlertPanel(@"No selection", @"Select one or more patterns before clicking.",
						@"OK", nil, nil);
		return FALSE;
	}
	return TRUE;
}

- (IBAction)remove:(id)sender {
	if ([self _selectionCheck]) {
		NSIndexSet*	srows	= [m_patternTable selectedRowIndexes];
		int			i;
		for (i = [srows lastIndex]; i >= [srows firstIndex]; i--) 
			if ([srows containsIndex:i]) {
				[m_patterns removeObjectAtIndex:i];
				[m_patternsMenu removeItemAtIndex:i];
			}
		
		[m_patternTable reloadData];
	}
}

#pragma mark -
#pragma mark Datasource

- (int)numberOfRowsInTableView:(NSTableView*)tv {
	return [m_patterns count];
}

- (id)tableView:(NSTableView*)tv objectValueForTableColumn:(NSTableColumn*)col row:(int)rowIndex {
	return [m_patterns objectAtIndex:rowIndex];
}

#pragma mark -
#pragma mark Selector for created pattern menu items

- (void)_patternItemAction:(id)sender {
	[m_patternField setStringValue:[sender title]];
	
}

@end
