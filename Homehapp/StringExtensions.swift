// The MIT License (MIT)
//
// Copyright (c) 2015 Qvik (www.qvik.fi)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

/// Extensions to the String class.
extension String {
    /**
    Adds a read-only length property to String.
    
    - returns: String length in number of characters.
    */
    public var length: Int {
        return self.characters.count
    }

    /** 
     Trims all the whitespace-y / newline characters off the begin/end of the string.
     
     - returns: a new string with all the newline/whitespace characters removed from the ends of the original string
     */
    public func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }

    /**
    Returns an URL encoded string of this string.
    
    - returns: String that is an URL-encoded representation of this string.
    */
    public var urlEncoded: String? {
        get {
            return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        }
    }

    /**
    Convenience method for a more familiar name for string splitting.
    
    - parameter separator: string to split the original string by
    - returns: the original string split into parts
    */
    public func split(separator: String) -> [String] {
        return componentsSeparatedByString(separator)
    }
    
    /**
    Checks whether the string contains a given substring.
    
    - parameter s: substring to check for
    - returns: true if this string contained the given substring, false otherwise.
    */
    public func contains(s: String) -> Bool {
        return (self.rangeOfString(s) != nil)
    }
    
    /**
    Returns a substring of this string from a given index up the given length.
    
    - parameter startIndex: index of the first character to include in the substring
    - parameter length: number of characters to include in the substring
    - returns: the substring
    */
    public func substring(startIndex startIndex: Int, length: Int) -> String {
        let start = self.startIndex.advancedBy(startIndex)
        let end = self.startIndex.advancedBy(startIndex + length)
        
        return self[start..<end]
    }
    
    /**
    Returns a substring of this string from a given index to the end of the string.
    
    - parameter startIndex: index of the first character to include in the substring
    - returns: the substring from startIndex to the end of this string
    */
    public func substring(startIndex startIndex: Int) -> String {
        let start = self.startIndex.advancedBy(startIndex)
        return self[start..<self.endIndex]
    }
    
    /**
    Splits the string into substring of equal 'lengths'; any remainder string
    will be shorter than 'length' in case the original string length was not multiple of 'length'.
    
    - parameter length: (max) length of each substring
    - returns: the substrings array
    */
    public func splitEqually(length length: Int) -> [String] {
        var index = 0
        let len = self.length
        var strings: [String] = []
        
        while index < len {
            let numChars = min(length, (len - index))
            strings.append(self.substring(startIndex: index, length: numChars))
            
            index += numChars
        }
        
        return strings
    }
}