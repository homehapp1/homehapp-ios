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
A view usable as a 'dimmer' view for dimming a background and receiving a
touch event (through a callback closure) for dismissing foreground elements.

Set ```touchedCallback``` to receive touch events.

By default this view's background is black. Set the alpha (default: 0.5) as required.

Sample usage:

```swift
dimmerView = TouchDetectView(frame: window!.frame)
dimmerView?.touchedCallback = { [weak self] in
self?.hideSomethingAndDisposeOfDimmerView()
}
window!.addSubview(dimmerView!)
```
*/
public class TouchDetectView: UIView {
    /// Called when this view was touched.
    public var touchedCallback: (Void -> Void)?
    
    func tapped() {
        touchedCallback?()
    }
    
    private func commonInit() {
        alpha = 0.5
        backgroundColor = UIColor.blackColor()
        userInteractionEnabled = true
        
        // Add tap recognizer for the image
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tapped")
        addGestureRecognizer(tapRecognizer)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
}
