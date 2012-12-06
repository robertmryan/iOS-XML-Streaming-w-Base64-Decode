//
//  XmlParserNSXMLParser.m
//  Streaming XML
//
//  Created by Robert Ryan on 12/5/12. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

/*
 Portions adapted from Apple's CocoaXMLParser.m
 Abstract: Subclass of iTunesRSSParser that uses libxml2 for parsing the XML data.
 Version: 1.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "XmlParserNSXMLParser.h"
#import "XmlParserDelegate.h"

@interface XmlParserNSXMLParser () <NSXMLParserDelegate>

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, strong) NSXMLParser *parser;

@end

@implementation XmlParserNSXMLParser

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self)
    {
        _url = [url copy];
    }
    
    return self;
}

- (void)parse
{
    self.parser = [[NSXMLParser alloc] initWithContentsOfURL:self.url];
    self.parser.delegate = self;
    [self.parser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([self.delegate respondsToSelector:@selector(parserDidStartElement:)])
        [self.delegate parserDidStartElement:elementName];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([self.delegate respondsToSelector:@selector(parserDidEndElement:)])
        [self.delegate parserDidEndElement:elementName];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if ([self.delegate respondsToSelector:@selector(parserFoundCharacters:)])
        [self.delegate parserFoundCharacters:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    if ([self.delegate respondsToSelector:@selector(parserErrorOccurred:)])
        [self.delegate parserErrorOccurred:parseError];
    self.parser = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    if ([self.delegate respondsToSelector:@selector(parserDidEndDocument)])
        [self.delegate parserDidEndDocument];
    self.parser = nil;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    if ([self.delegate respondsToSelector:@selector(parserDidStartDocument)])
        [self.delegate parserDidStartDocument];
}

//#pragma mark - stream methods
//
////When creating the NSURLConnection and parser:
//- (void)doMagicParsingStuff:(NSURL *)url
//{
//    CFReadStreamRef readStream;
//    CFWriteStreamRef writeStream;
//    CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 4096);
//
//    NSInputStream *istream = (__bridge_transfer NSInputStream *)readStream;
//    NSOutputStream *ostream = (__bridge_transfer NSOutputStream *)writeStream;
//
//    self.networkOutputStream = ostream;
//    self.networkInputStream = istream;
//
//    self.buffer = [NSMutableData data];
//
//    [ostream setDelegate:self];
//    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//    [istream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
//    [ostream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
//    self.finishedLoading = NO;
//    [istream open];
//    [ostream open];
//
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
//    NSAssert(connection, @"unable to open connection");
//
//    NSXMLParser *parser = [[NSXMLParser alloc] initWithStream:istream];
//    parser.delegate = self;
//    [parser parse];
//
//}
//
//- (void)attemptToWriteToStream
//{
//    NSLog(@"%s buffer=%d", __FUNCTION__, [self.buffer length]);
//    //    NSLog(@"%s buffer=%@", __FUNCTION__, [[NSString alloc] initWithData:self.buffer encoding:NSUTF8StringEncoding]);
//
//    NSUInteger written = [self.networkOutputStream write:[self.buffer bytes] maxLength:[self.buffer length]];
//    [self.buffer replaceBytesInRange:NSMakeRange(0,written) withBytes:"" length:0];
//}
//
//// In the output stream delegate:
//- (void)stream:(NSStream *)s handleEvent:(NSStreamEvent)event
//{
//    NSLog(@"%s event=%d", __FUNCTION__, event);
//
//    if (NSStreamEventHasSpaceAvailable == event)
//    {
//        if (self.finishedLoading && [self.buffer length] == 0)
//        {
//            [self.networkOutputStream close];
//        }
//        else
//        {
//            if ([self.buffer length] > 0)
//                [self attemptToWriteToStream];
//        }
//    }
//}
//
//// In the NSURLConnection Delegate:
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    NSLog(@"%s length=%d", __FUNCTION__, [data length]);
//
//    [self.buffer appendData:data];
//    [self attemptToWriteToStream];
//}
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    NSLog(@"%s", __FUNCTION__);
//
//    self.finishedLoading = YES;
//}

@end
