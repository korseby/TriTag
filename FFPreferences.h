// $Id: FFPreferences.h 243 2004-08-12 18:14:36Z ravemax $

@interface FFPreferences : NSObject {	
	NSString*	m_freeDBSearchURL;
	NSString*	m_resultPattern;
	NSString*	m_yearPattern;
	NSString*	m_trackPattern;
}

- (NSString*)freeDBSearchURL;
- (NSString*)resultPattern;
- (NSString*)yearPattern;
- (NSString*)trackPattern;

@end
