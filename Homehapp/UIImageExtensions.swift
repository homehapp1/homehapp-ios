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
import UIKit
import Accelerate

/// Extensions to the UIImage class
extension UIImage {
    /// Provides a shorthand for image width.
    public var width: CGFloat {
        return self.size.width
    }
    
    /// Provides a shorthand for image height.
    public var height: CGFloat {
        return self.size.height
    }
    
    /**
     Returns an image with orientation 'removed', ie. rendered again so that
     imageOrientation is always 'Up'. If this was the case already, the original image is returned.
     
     - returns: a copy of this image with orientation setting set to 'up'.
     */
    public func imageWithNormalizedOrientation() -> UIImage {
        if ( imageOrientation == .Up ) {
            return self;
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale);
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        drawInRect(rect)
        
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return normalizedImage;
    }
    
    /**
     Returns an scaled-down (to the max size) image of the original image, or the
     original image if max size was not exceeded. Aspect ratio is preserved.
     
     - parameter maxSize: maximum size for the new image
     - parameter imageScale: value for UIImage.scale. Specify 0.0 to match the scale of the device's screen.
     - returns: scaled-down image
     */
    public func scaleDown(maxSize maxSize: CGSize, imageScale: CGFloat = 1.0) -> UIImage {
        let myWidth = self.size.width
        let myHeight = self.size.height
        
        if maxSize.height >= myHeight && maxSize.width >= myWidth {
            return self
        }
        
        let fittingSize = self.size.aspectSizeToFit(maxDimensions: maxSize)
        
        return scaleTo(size: fittingSize, imageScale: imageScale)
    }
    
    /**
     Returns a scaled version of this image that 'aspect-fits' inside a given size. Aspect ratio is retained.
     
     - parameter sizeToFit: max dimensions for the scaled image.
     - parameter imageScale: value for UIImage.scale. Specify 0.0 to match the scale of the device's screen.
     - returns: scaled image
     */
    public func scaleToFit(sizeToFit sizeToFit: CGSize, imageScale: CGFloat = 1.0) -> UIImage {
        let fittingSize = self.size.aspectSizeToFit(maxDimensions: sizeToFit)

        return scaleTo(size: fittingSize, imageScale: imageScale)
    }
    
    /**
     Returns a scaled version of this image. The image is stretched to the given size, thus possibly 
     changing the aspect ratio.
     
     - parameter scaledSize: size for the scaled image. Specify ```imageScale: 1.0``` to make this exact pixel size.
     - parameter imageScale: value for UIImage.scale. Specify 0.0 to match the scale of the device's screen.
     - returns: scaled-down image
     */
    public func scaleTo(size size: CGSize, imageScale: CGFloat = 1.0) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, imageScale)
        self.drawInRect(CGRect(origin: CGPointZero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }
    
    /**
     Crops the image to a square; from the middle of the original image, using the largest
     possible square area that fits in the original image.
     
     - returns: the cropped image. Note that the dimensions may be off by +-1 pixels.
     */
    public func cropImageToSquare() -> UIImage {
        let contextImage: UIImage = UIImage(CGImage: self.CGImage!)
        
        let contextSize: CGSize = contextImage.size
        
        let posX: CGFloat
        let posY: CGFloat
        let width: CGFloat
        let height: CGFloat
        
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            width = contextSize.height
            height = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            width = contextSize.width
            height = contextSize.width
        }
        
        let rect: CGRect = CGRectMake(posX, posY, width, height)
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)!
        let image: UIImage = UIImage(CGImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        
        return image
    }

    /// Blur algorithms
    public enum BlurAlgorithm {
        case BoxConvolve
        case TentConvolve
    }

    /**
     Returns a blurred version of the image.
     
     - parameter radius: radius of the blur kernel, in pixels.
     - parameter algorithm: blur algorithm to use. .TentConvolve is faster than .BoxConvolve.
     - returns: the blurred image.
    */
    public func blurImage(radius radius: Double, algorithm: BlurAlgorithm = .TentConvolve) -> UIImage {
        let imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        
        func createEffectBuffer(context: CGContext) -> vImage_Buffer {
            let data = CGBitmapContextGetData(context)
            let width = vImagePixelCount(CGBitmapContextGetWidth(context))
            let height = vImagePixelCount(CGBitmapContextGetHeight(context))
            let rowBytes = CGBitmapContextGetBytesPerRow(context)
            
            return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.mainScreen().scale)
        let effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage); // this takes time
        var effectInBuffer = createEffectBuffer(effectInContext!)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
        let effectOutContext = UIGraphicsGetCurrentContext()
        var effectOutBuffer = createEffectBuffer(effectOutContext!)
        
        let inputRadius = CGFloat(radius) * UIScreen.mainScreen().scale
        var radius = UInt32(floor(inputRadius * 3.0 * CGFloat(sqrt(2 * M_PI)) / 4 + 0.5))
        if radius % 2 != 1 {
            radius += 1 // force radius to be odd
        }
        
        let imageEdgeExtendFlags = vImage_Flags(kvImageEdgeExtend)
        
        if algorithm == .BoxConvolve {
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
        } else {
            vImageTentConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
        }
        
        let effectImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        UIGraphicsEndImageContext()
        
        return effectImage
    }

    public func averageColor() -> UIColor {
        var bitmap = [UInt8](count: 4, repeatedValue: 0)
        
        // Get average color.
        let context = CIContext()
        let inputImage = CIImage ?? CoreImage.CIImage(CGImage: CGImage!)
        let extent = inputImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        let filter = CIFilter(name: "CIAreaAverage", withInputParameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
        let outputImage = filter.outputImage!
        let outputExtent = outputImage.extent
        assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
            
        // Render to bitmap.
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
        return result
    }

}

