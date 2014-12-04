# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Hello world using the Cocoa framework
module cocoa_message_box

in "ObjC" `{
	#import <Foundation/Foundation.h>
`}

fun dialog in "ObjC" `{
    @autoreleasepool {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert setMessageText:@"Hi there."];
		[alert runModal];
    }
`}

fun dialog1 in "ObjC" `{
    @autoreleasepool {
		[alert beginSheetModalForWindow:window
		       modalDelegate:self
		       didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
		       contextInfo:nil];
    }
`}

dialog
dialog1
