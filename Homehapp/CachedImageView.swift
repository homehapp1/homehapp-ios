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

import UIKit

/**
An UIImageView that retrieves the image from ImageCache (default shared instance).
*/
@IBDesignable
public class CachedImageView: QvikImageView {
    /// Placeholder image view; used to display a temporary image (smaller or thumbnail) while actual image loads
    private var placeholderImageView: UIImageView? = nil
    
    /// Single-color placeholder view in case there is no placeholder image
    private var fadeInView: UIView? = nil
    
    /// Frame for fade in color
    public var fadeInFrame: CGRect = CGRectZero
    
    /// Duration for fading in the loaded image, in case it is asynchronously loaded.
    @IBInspectable
    public var imageFadeInDuration: NSTimeInterval = 0.3
    
    /// JPEG thumbnail data for the image. Should set this before layout cycle.
    public var thumbnailData: NSData? = nil
    
    /// Color for a fade-in view; used in case ```thumbnailData``` is not set
    @IBInspectable
    public var fadeInColor: UIColor? = nil
    
    /// Placeholder image; displayed while actual image loads.
    public var placeholderImage: UIImage? = nil
    
    /// ImageCache instance to use. Default value is the shared instance.
    public var imageCache = ImageCache.sharedInstance()
    
    /// Callback to be called when the image changes.
    public var imageChangedCallback: (Void -> Void)?
    
    /// Whether to automaticallty respond to image load notification
    @IBInspectable
    public var ignoreLoadNotification = false
    
    override public var image: UIImage? {
        didSet {
            imageChangedCallback?()
        }
    }
    
    /// Image URL. Setting this will cause the view to automatically load the image
    public var imageUrl: String? = nil {
        didSet {
            assert(NSThread.isMainThread(), "Must be called on main thread!")

            reset()
            
            if imageUrl?.length <= 0 {
                self.image = nil
                return
            }
            
            if let imageUrl = imageUrl {
                if imageUrl == oldValue {
                    // No need to do anything
                    return
                }
                
                self.image = imageCache.getImage(url: imageUrl, loadPolicy: .Network)
            }
        }
    }

    /// Resets all the properties (extra views etc) to the original state
    private func reset() {
        placeholderImageView?.removeFromSuperview()
        placeholderImageView = nil
        fadeInView?.removeFromSuperview()
        fadeInView = nil
    }

    /**
     The image for this image view has been loaded into the in-memory cache and is available
     for use. The default behavior is to set the image object property from the cache for display.
     
     Extending classes may override this to change the default behavior.
     */
    public func imageLoaded() {
        if let imageUrl = self.imageUrl {
            if let image = ImageCache.sharedInstance().getImage(url: imageUrl, loadPolicy: .Memory) {
                // Image loaded & found
                self.image = image
                
                // Fade out the thumbnail view
                UIView.animateWithDuration(imageFadeInDuration, animations: {
                    self.placeholderImageView?.alpha = 0.0
                    self.fadeInView?.alpha = 0.0
                    }, completion: { finished in
                        self.reset()
                })
            }
        }
    }
    
    func imageLoadedNotification(notification: NSNotification) {
        assert(NSThread.isMainThread(), "Must be called on main thread!")
        
        if ignoreLoadNotification {
            return
        }
        
        if let imageUrl = notification.userInfo?[ImageCache.urlParam] as? String {
            if imageUrl == self.imageUrl {
                imageLoaded()
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if image == nil {
            // No image yet; show a placeholder / thumbnail image if present
            if let placeholderImage = placeholderImage {
                if placeholderImageView == nil {
                    placeholderImageView = UIImageView(frame: self.bounds)
                    placeholderImageView!.contentMode = self.contentMode
                    placeholderImageView!.image = placeholderImage
                    image = placeholderImageView!.image
                    insertSubview(placeholderImageView!, atIndex: 0)
                    
                    // Discard reference to the placeholder image to deallocate it when actual image has loaded
                    self.placeholderImage = nil
                    
                    // Add constraints
                    let leadingConstraint = NSLayoutConstraint(item: placeholderImageView!, attribute:
                        .LeadingMargin, relatedBy: .Equal, toItem: self,
                                        attribute: .LeadingMargin, multiplier: 1.0,
                                        constant: 0)
                    
                    let trailingConstraint = NSLayoutConstraint(item: placeholderImageView!, attribute:
                        .TrailingMargin, relatedBy: .Equal, toItem: self,
                                        attribute: .TrailingMargin, multiplier: 1.0,
                                        constant: 0)
                    
                    let topConstraint = NSLayoutConstraint(item: placeholderImageView!, attribute:
                        .TopMargin, relatedBy: .Equal, toItem: self,
                                         attribute: .TopMargin, multiplier: 1.0,
                                         constant: 0)
                    
                    let bottomConstraint = NSLayoutConstraint(item: placeholderImageView!, attribute:
                        .BottomMargin, relatedBy: .Equal, toItem: self,
                                    attribute: .BottomMargin, multiplier: 1.0,
                                    constant: 0)
                    
                    placeholderImageView!.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activateConstraints([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
                    
                } else {
                    placeholderImageView!.frame = self.frame
                }
            } else if let thumbnailData = thumbnailData {
                if placeholderImageView == nil {
                    placeholderImageView = UIImageView(frame: self.bounds)
                    placeholderImageView!.contentMode = self.contentMode
                    placeholderImageView!.image = jpegThumbnailDataToImage(data: thumbnailData, maxSize: self.frame.size)
                    image = placeholderImageView!.image
                    insertSubview(placeholderImageView!, atIndex: 0)
                    
                    // Discard reference to thumbnail data to to deallocate it when actual image has loaded
                    self.thumbnailData = nil
                } else {
                    placeholderImageView!.frame = self.frame
                }
            } else if let fadeInColor = fadeInColor where placeholderImageView == nil {
                if fadeInView == nil {
                    // No thumbnail data set; show a colored fade-in view
                    let frame = fadeInFrame != CGRectZero ? fadeInFrame : self.frame
                    fadeInView = UIView(frame: frame)
                    insertSubview(fadeInView!, atIndex: 0)
                } else {
                    let frame = fadeInFrame != CGRectZero ? fadeInFrame : self.frame
                    fadeInView!.frame = frame
                }
                fadeInView!.backgroundColor = fadeInColor
            }
        }
    }
    
    private func commonInit() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CachedImageView.imageLoadedNotification(_:)), name: ImageCache.cacheImageLoadedNotification, object: nil)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
}

