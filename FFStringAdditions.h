// $Id: FFStringAdditions.h 209 2004-07-13 14:18:21Z ravemax $

@interface NSString (FFStringAdditions)

// returns NSNotFound if the character wasn't found
- (unsigned)indexOfCharacter:(unichar)chr startingAtIndex:(unsigned)index;

@end
