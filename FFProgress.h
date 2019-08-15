// $Id: FFProgress.h 264 2004-08-20 14:22:11Z ravemax $

@interface FFProgress : NSObject
{
    IBOutlet NSWindow*				m_mainWin;
    IBOutlet NSProgressIndicator*	m_progressBar;
    IBOutlet NSWindow*				m_progressWin;
    IBOutlet NSTextField*			m_text;
	
	NSLock*	m_tlock;
}

- (void)startWithText:(NSString*)txt;
- (void)stop;

@end
