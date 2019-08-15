// $Id: FFDropWindow.h 209 2004-07-13 14:18:21Z ravemax $

@interface FFDropWindow : NSWindow
{
	id	dropObject;
	SEL	dropSelector;
}

- (void)setDropObject:(id)obj andSelector:(SEL)sel;

@end
