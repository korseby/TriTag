/*
 *	FFSupport.m
 *
 *	Created by Patrick Gleichmann on Fri May 16 2003.
 *	Copyright (c) 2003-2004 FEEDFACE.com. All rights reserved.
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; either version 2 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details. 
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program; if not, write to the Free Software
 *	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

RCS_ID("$Id: FFSupport.m 209 2004-07-13 14:18:21Z ravemax $")

#import "FFSupport.h"

static NSString* VersionListURL = @"http://www.feedface.com/projects/versionlist.xml";

@implementation FFSupport 

+ (void)updatesCheckForProject:(NSString*)project {
	NSDictionary*   versionList;
	
	// Fetch project version xml file
	versionList = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:VersionListURL]];
	if (versionList == nil)
		NSRunAlertPanel(@"Network problems", @"Failed to fetch the project version list", @"OK", nil, nil);		
	
	else {
		NSString*		bundleVersion, *siteVersion;
		NSDictionary*	projDict;
	
		// Extract versions
		bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
		projDict = [versionList objectForKey:project];
		if (projDict == nil)
			NSRunAlertPanel(@"Error in the project version list", @"Please contact us", @"OK", nil, nil);
		
		else {
			siteVersion = [projDict objectForKey:@"Version"];

			// Compare versions
			if ([bundleVersion isEqualToString:siteVersion])
				NSRunInformationalAlertPanel(@"Your version is up to date", @"Thanks for the check anyway", @"OK", nil, nil);
			else {
				int ret = NSRunInformationalAlertPanel(@"New version available", [NSString stringWithFormat:@"Version %@ was released (%@).\nWant to download now ?", siteVersion, [projDict objectForKey:@"Date"]], @"Download", @"Cancel", nil);
				if (ret == NSOKButton)
					[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[projDict objectForKey:@"File"]]];
			}
		}
	}
}

+ (void)sendFeedbackToMailaddress:(NSString*)mailTo {	
	NSString*			subj;
	NSMutableString*	esubj;
	NSDictionary*		idict;
	NSURL*				mu;
	
	// Get the subject
	subj = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleShortVersionString"];
	if ((subj == nil) || ([subj length] == 0)) {
		idict = [[NSBundle mainBundle] infoDictionary];
		subj = [NSString stringWithFormat:@"%@ %@",
			[idict objectForKey:@"CFBundleExecutable"], [idict objectForKey:@"CFBundleVersion"]];
	}
	
	// Escape string (stringByAddingPercentEscapesUsingEncoding: does this but only available in 10.3)
	esubj = [NSMutableString stringWithString:subj];
	[esubj replaceOccurrencesOfString:@" " withString:@"%20" options:0 range:NSMakeRange(0, [esubj length])];
	
	// Open mail agent
	mu = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@?subject=%@:", mailTo, esubj]];
	if (![[NSWorkspace sharedWorkspace] openURL:mu])
		NSRunAlertPanel(@"Failed to open the mail agent",
						[NSString stringWithFormat:@"Mail address: %@\nPlease add '%@' to the subject.",
							mailTo, subj], @"OK", nil, nil);
}

@end
