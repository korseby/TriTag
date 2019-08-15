//RCS_ID("$Id: FFProgress.m 264 2004-08-20 14:22:11Z ravemax $")

#import "FFProgress.h"

@implementation FFProgress

- (id)init {
	self = [super init];
	if (self != nil)
		m_tlock = [[NSLock alloc] init];
	return self;
}

- (void)dealloc {
	[m_tlock release];
	[super dealloc];
}

- (void)_sthread:(id)arg {
	NSAutoreleasePool*	pool = [[NSAutoreleasePool alloc] init];
	
	[m_progressBar startAnimation:self];
	[m_tlock lock]; [m_tlock unlock];
	[m_progressBar stopAnimation:self];
	
	[pool release];
}


- (void)startWithText:(NSString*)txt {
	[m_text setStringValue:txt];

	[NSApp beginSheet:m_progressWin modalForWindow:m_mainWin modalDelegate:self 
	   didEndSelector:nil contextInfo:NULL];

	[m_progressWin makeKeyAndOrderFront:self];

	[m_tlock lock];
	[m_progressBar setUsesThreadedAnimation:TRUE];
	[NSThread detachNewThreadSelector:@selector(_sthread:) toTarget:self withObject:nil];
}

- (void)stop {	
	[m_tlock unlock];	

	[NSApp endSheet:m_progressWin];
	[m_progressWin orderOut:NULL];
}

@end
