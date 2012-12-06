# iOS XML Streaming with Base64-decoding

--

## Introduction

This is an iOS application, created in response to a question on Stack Overflow, [Decoding a HUGE NSString, running out of memory](http://stackoverflow.com/questions/13691787). This demonstrates how to use `LibXML2` to parse a very large XML file as it is being streamed from a web server, avoiding the problems introduced by `NSXMLParser` which has a tendency to load the entire (or at least very large portions) of an XML file into memory before initiating the XML parsing process.

This answer was inspired by Apple's [XMLPerformance sample code](https://developer.apple.com/library/ios/#samplecode/XMLPerformance/Introduction/Intro.html#//apple_ref/doc/uid/DTS40008094), which illustrates the two different XML parsers, `LibXML2` and `NSXMLParser`.

## The Technical Problem

When an app is parsing some server-based XML file, many implementations will simply load the entire XML file into memory before attempting the parsing the file. Most XML files are reasonably small, so this generally isn't an issue. For large files (e.g. measured in tens or hundreds of megabytes), this becomes problematic.

Notably, the Cocoa iOS XML parser, `NSXMLParser` suffers from this problem. The nature of the interface might lead one to assume that, especially as a SAX parser, that it might be conservative in terms of the memory footprint. In practice, though, it seems to be aggressive about trying to load as much of the XML file into memory at any given time. This appears to be true whether one uses the `initWithContentsOfURL`, `initWithStream`, or (obviously) `initWithData`.

## A Possible Solution

In Apple's XMLPerformance sample project, though, they demonstrate how one can take advantage of the streaming possibilities offered by `NSURLConnection` in conjunction with the `LibXML2` XML parser to minimize the memory footprint. While this `NSURLConnection` technique is not easily done with `NSXMLParser`, it's quite simple with the `LibXML2` parser. Anyway, this sample project demonstrates the two parsers, so one can compare and contrast the memory footprint of the two techniques. 

Personally, I think the particular implementation in that project is a little questionable, with model-related logic embedded in both the view controller as well as the two XML classes. In this project, I've tried to isolate this logic in a single method (in my case, the view controller), leaving fairly minimalist XML implementations. My particular implementations certainly have opportunities for further optimization, but hopefully it illustrates the nature of the difference.

As a data point, with a 56mb XML file, the `NSXMLParser` implementation had a maximum footprint of between 100-200mb, whereas the `LibXML2` implementation had a maximum footprint of less than 2mb. It even seems to be a little quicker.

## Configuration for LibXML2

In order to use the `LibXML2` parser, you must:

- Add the `libxml2.dylib` to your project. You do this by selecting your app's target in the top of the left side "Navigation" panel, selecting the "TARGET" for your app, clicking on the "Build Phases" tab, expanding the "Link Binaries with Libraries" section, clicking on the "+" button, and choosing the `libxml2.dylib` library.

- Add the `libxml2` headers you your search path. You do this by selecting your app's target in the top of the left side "Navigation" panel, selecting the "TARGET" for your app, clicking on the "Build Settings" tab, finding the entry for "Header Search Paths", double clicking on that, clicking on the "+" button and adding an entry for "`$SDKROOT/usr/include/libxml2`" (without the quotes).

## Classes, Protocols, and Categories

The classes in this project include:

- `AppDelegate` - the standard app delegate class.

- `ViewController` - a simple view controller class with two buttons that initiates the two types of XML parsing.

- `XmlParserDelegate` - a simple protocol that the two XML parsing classes (listed below) conform to. The idea was to provide `ViewController` a unified interface for parsing XML, regardless of which XML parsing engine/technique was used.

- `XmlParserNSXMLParser` - a class that performs a `NSXMLParser`-based parsing of the XML.

- `XmlParserLibXML` - a class that performs a `LibXML`-based parsing of the XML.

- `NSData+Base64` - a `NSData` category written by Matt Gallagher that performs Base64 encoding and decoding. See [his article on Cocoa With Love](http://www.cocoawithlove.com/2009/06/base64-encoding-options-on-mac-and.html) for more information.

- [How To Choose The Best XML Parser for Your iPhone Project](http://www.raywenderlich.com/553/how-to-chose-the-best-xml-parser-for-your-iphone-project) is an article on Ray Wenderlich's site that walks through some considerations when choosing an XML parser for you iOS app.

## Server code for generating a large XML file

This app is designed for parsing a very large XML file. You presumably already have a XML source that is generating a very large XML file (otherwise, you wouldn't be reading this), but just for reference purposes, the way I'm generating my large XML file using this custom PHP code. (I'm not a PHP programmer, so my apologies for the primitive implementation.)

    <files>
      <file>
        <filename><?php
      
          $filename = "my-very-big-file.bin";  // replace this with the name of your big file
          echo $filename;
      
        ?></filename>
        <base64><?php
    
          $handle = fopen($filename, "r");
        
          while (!feof($handle))
          {
              $contents = fread($handle, 57);  // 57 bytes in input file translates to base64 lines of 76 characters each
              $base64_contents = base64_encode($contents);
            
              echo $base64_contents;
          }
        
          fclose($handle);
    
        ?></base64>
      </file>
    </files>

This ends up generating a XML file that looks like:

    <files>
      <file>
        <filename>my-very-big-file.bin</filename>
        <base64>PCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBYSFRNTCAxLjAgVHJhbnNpdGlvbmFs
           .
           .
           .
        </base64>
      </file>
    </files>

The parsing logic in `ViewController.m` is therefore looking for

1. The `filename` tag, so it knows what name to use for the file; and 

2. The `base64` tag, which will have the Base64 representation of the file's contents.

Your XML format may obviously vary, so alter the `XmlParserDelegate` methods in `ViewController.m` accordingly.

## Limitations

It's worth noticing that this Base64-decoding algorithm, because it's doing the conversion for subsets of the full data stream, has to detect whether the individual subsets of data end on what I call a Base64-friendly boundary. Notable, the Base64 encoding takes three bytes with 8 bits of data each (24 bits of data in total), and translates that to four characters with 6 bits of data. Likewise, the Base64-decoding process takes four characters with 6 bits of data each, and converts that into three bytes with 8 bits of data each. Thus, since we're parsing fragments of data, the algorithm looks to see if the fragment ends on a 4 character boundary, and if not, it sets the extra characters aside to be included in the next fragment.

This technique only works if the Base64 stream is free of newline characters (e.g. carriage returns, linefeeds, etc.) and any whitespace characters. Some Base64-encoded streams, though, include newline characters every 76 or 64 characters. If your Base64 data source has newline characters or any whitespace, you may have to revisit the algorithm in the `parserFoundCharacters` method of `ViewController.m`.

Likewise, the `XmlParserDelegate` methods in `ViewController.m` are highly dependent upon the format of the XML file (e.g. the demonstration assumes the `filename` tag demarcates the name of the file, followed by a `base64` tag with the contents of the binary file). You will need to customize this algorithm to match your particular XML format.

Finally, this is an ARC project and the code may need to be altered for a non-ARC environment. The `NSDate+Base64` category, though, is not ARC-code, and therefore has been tagged as `-fno-objc-arc`. For more information about the `-fno-objc-arc` setting, please refer to the [Use Compiler Flags to Enable and Disable ARC](http://developer.apple.com/library/ios/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html#//apple_ref/doc/uid/TP40011226-CH1-SW15) in the _Transitioning to ARC Release Notes._  

## References

- [Decoding a HUGE NSString, running out of memory](http://stackoverflow.com/questions/13691787), the Stack Overflow question that prompted my research on this topic.

- See [Matt Gallagher's article on Cocoa With Love](http://www.cocoawithlove.com/2009/06/base64-encoding-options-on-mac-and.html) about the `NSData+Base64` category.

- [Wikipedia entry for Base64](http://en.wikipedia.org/wiki/Base64).

- [LibXML2 XML C Parser and Toolkit](http://www.xmlsoft.org).

- Apple's [NSXMLParser Class Reference](https://developer.apple.com/library/ios/#documentation/Cocoa/Reference/Foundation/Classes/NSXMLParser_Class/Reference/Reference.html).

- For a discussion of ARC (Automatic Reference Counting) please see the [Transitioning to ARC Release Notes](http://developer.apple.com/library/ios/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html).

## Caveats

While I'm demonstrating the process for parsing huge XML files with Base64 data on iOS devices, it shouldn't be overlooked that Base64 is probably not a good mechanism for transmitting very large binaries. A Base64-encoded string is 33% larger than the equivalent binary transmission. So this project should not be seen as an endorsement of large Base64 data elements, but rather a suggestion on how you might best handle them if you have no other choices.

## Notes

This was developed using Xcode 4.5.2 for devices running iOS 5 or later.

## Contact information

If you have any questions, do not hesitate to contact me at:

Rob Ryan
robert.ryan@mindspring.com

5 December 2012
