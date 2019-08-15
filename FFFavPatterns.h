// $Id: FFFavPatterns.h 243 2004-08-12 18:14:36Z ravemax $

@interface FFFavPatterns : NSObject {
    IBOutlet NSTextField*	m_patternField;
    IBOutlet NSMenu*		m_patternsMenu;
    IBOutlet NSTableView*	m_patternTable;
    IBOutlet NSWindow*		m_win;
	
	NSMutableArray*	m_patterns;
}

- (IBAction)addCurrentPattern:(id)sender;
- (IBAction)editPatterns:(id)sender;
- (IBAction)remove:(id)sender;

@end
