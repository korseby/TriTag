RCS_ID("$Id: FFStringAdditions.m 209 2004-07-13 14:18:21Z ravemax $")

#import "FFStringAdditions.h"

@implementation NSString (FFStringAdditions)

- (unsigned)indexOfCharacter:(unichar)chr startingAtIndex:(unsigned)index {
	unsigned len = [self length];

	while (index < len) {
		if ([self characterAtIndex:index] == chr)
			return index;
		index++;
	}
	
	return NSNotFound;
}

@end
