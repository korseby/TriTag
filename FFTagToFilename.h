// $Id: FFTagToFilename.h 209 2004-07-13 14:18:21Z ravemax $

@class FFData;

typedef enum {
	ASK_DIALOG = 0,
	KEEP_ORG_NAME,
	RETURN_EMPTY
} EmptyTagAction;

@interface FFTagToFilename : NSObject
{
	NSString*		m_patStr;
	id				m_optObj;
	EmptyTagAction	m_emptyTagAction;
}

- (id)initWithPattern:(NSString*)patStr andOpts:(id)optObj;
- (NSString*)filenameFromTag:(NSDictionary*)row;

+ (NSMutableString*)replaceInvalidCharacters:(NSString*)fname;


@end
