//
//  ViewController.m
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

#import "ViewController.h"

#import "XmlParserDelegate.h"
#import "XmlParserLibXML.h"
#import "XmlParserNSXMLParser.h"

#import "NSData+Base64.h"


#pragma mark - Constants

#warning Review the following 3 constants for your XML URL and the appropriate tag names 

// the URL

#define kXmlUrl @"http://www.robertmryan.com/test/hugefile.php"

// the tag names in the XML file

#define kFilenameElementName @"filename"
#define kBase64DataElementName @"base64"


#pragma mark - Private class extension

@interface ViewController () <XmlParserDelegate>

@property (nonatomic, getter = isParsingFile) BOOL parsingFile;
@property (nonatomic, strong) NSMutableString *filename;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSString *extraBytes;
@property (nonatomic, strong) NSDate *startTimestamp;
@property (nonatomic, strong) NSString *currentElementName;

@end

#pragma mark - Implementation

@implementation ViewController

#pragma mark - XmlParserDelegate Methods

- (void)parserDidStartElement:(NSString *)elementName
{
    self.parsingFile = NO;
    
    self.currentElementName = elementName;
    
    if ([elementName isEqualToString:kFilenameElementName])
    {
        self.filename = [NSMutableString string];
    }
    else if ([elementName isEqualToString:kBase64DataElementName])
    {
        self.parsingFile = YES;
        
        NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filenamePath = [documentsPath stringByAppendingPathComponent:self.filename];
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:filenamePath append:NO];
        [self.outputStream open];
        
        self.startTimestamp = [NSDate date];
    }
}

- (void)parserDidEndElement:(NSString *)elementName
{
    if ([elementName isEqualToString:kBase64DataElementName])
    {
        self.parsingFile = NO;
        
        if (self.extraBytes)
        {
            NSLog(@"%s there should be no extra bytes, but there are: %@", __FUNCTION__, self.extraBytes);
            
            NSAssert(self.extraBytes, @"there should be no extra bytes");
        }
        [self.outputStream close];

        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.startTimestamp];
        
        NSLog(@"Downloaded, parsed, and performed Base64 decode of \"%@\" in %.2f seconds", self.filename, elapsed);

        self.outputStream = nil;
        self.filename = nil;
        self.extraBytes = nil;
        self.startTimestamp = nil;
    }
    
    self.currentElementName = nil;
}

// note, this assumes that the string will have base64 characters without any extra characters

- (void)parserFoundCharacters:(NSString *)string
{
    if (self.isParsingFile)
        [self parseBase64Data:string];
    else if ([self.currentElementName isEqualToString:kFilenameElementName])
        [self.filename appendString:string];
}

- (void)parserDidEndDocument
{
}

- (void)parserDidStartDocument
{
}

#pragma mark - Parsing utility functions

- (void)parseBase64Data:(NSString *)string
{
    NSString *input;
    
    if (self.extraBytes)
        input = [self.extraBytes stringByAppendingString:string];
    else
        input = string;
    
    NSInteger extraBytesLength = [input length] % 4;
    
    if (extraBytesLength > 0 && [input length] > 4)
    {
        NSInteger indexOfExtraBytes = [input length] - extraBytesLength;
        self.extraBytes = [input substringFromIndex:indexOfExtraBytes];
        input = [input substringToIndex:indexOfExtraBytes];
    }
    else
        self.extraBytes = nil;
    
    [self convertAndWriteDataForString:input];
}

- (void)convertAndWriteDataForString:(NSString *)input
{
    NSData *output = [NSData dataFromBase64String:input];
    const uint8_t * dataBytes  = [output bytes];
    NSInteger dataLength = [output length];
    NSInteger bytesRemaining = dataLength;
    NSInteger bytesWrittenSoFar = 0;
    NSInteger bytesWritten;
    
    while (bytesRemaining > 0)
    {
        bytesWritten = [self.outputStream write:&dataBytes[bytesWrittenSoFar] maxLength:bytesRemaining];
        NSAssert(bytesWritten > 0, @"NSOutputStream write failure");
        bytesWrittenSoFar += bytesWritten;
        bytesRemaining -= bytesWritten;
    }
}


#pragma mark - IBAction methods

- (IBAction)pressedParseWithNSXMLButton:(id)sender
{
    NSURL *url = [NSURL URLWithString:kXmlUrl];
    
    XmlParserNSXMLParser *parser = [[XmlParserNSXMLParser alloc] initWithURL:url];
    parser.delegate = self;
    
    [parser parse];
}

- (IBAction)pressedParseWithLibXMLButton:(id)sender
{
    NSURL *url = [NSURL URLWithString:kXmlUrl];
    
    XmlParserLibXML *parser = [[XmlParserLibXML alloc] initWithURL:url];
    parser.delegate = self;
    
    [parser parse];
}

@end
