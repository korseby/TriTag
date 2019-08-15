RCS_ID("$Id: FFDropWindow.m 209 2004-07-13 14:18:21Z ravemax $")

#import "FFDropWindow.h"
#import "FFController.h"

@implementation FFDropWindow

- (void)awakeFromNib
{
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSArray* types;
	
	types = [[sender draggingPasteboard] types];
	if ([types containsObject:NSFilenamesPboardType] && ([sender draggingSourceOperationMask] & NSDragOperationGeneric))
		return NSDragOperationGeneric;

	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard*	pb;
	NSArray*		types, *files;
	
	pb = [sender draggingPasteboard];
	types = [pb types];
	if ([types containsObject:NSFilenamesPboardType]) {
		files = [pb propertyListForType:NSFilenamesPboardType];		
		
//		objc_msgSend(dropObject, dropSelector, files); // Damn GCC 3.3 breaks this code
		[(FFController*)dropObject filesWereDropped:files]; // Now hardwired
	}
	
	return TRUE;
}

- (void)setDropObject:(id)obj andSelector:(SEL)sel
{
	dropObject = obj;
	dropSelector  = sel;
}

@end
