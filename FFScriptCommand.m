RCS_ID("$Id: FFScriptCommand.m 234 2004-07-31 13:55:31Z ravemax $")

#import "FFScriptCommand.h"

NSString* ScriptCommandReceived = @"script_cmd_received";

@implementation FFScriptCommand

- (id)performDefaultImplementation {
	[[NSNotificationCenter defaultCenter] postNotificationName:ScriptCommandReceived object:self];
	return nil;
}

@end
