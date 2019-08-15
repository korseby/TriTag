// $Id: FFFilenameToTag.h 209 2004-07-13 14:18:21Z ravemax $

//#import <pcre.h>

@class FFPlaceholders;

@interface FFFilenameToTag : NSObject
{
	FFPlaceholders*	m_ph;
	id				m_optObj;

	NSString*		m_sepBefore, *m_sepAfter;
	NSMutableArray*	m_sepBetween;

//	pcre*			m_cre;
}

- (id)initWithString:(NSString*)pstr withOpts:(id)optObj;
- (NSDictionary*)tagFromFilename:(NSString*)fname;

@end
