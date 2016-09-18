

import UIKit

enum CircularSliderHandeType: Int {
    case semiTransparentWhiteCircle
    case semiTransparentBlackCircle
    case doubleCircleWithOpenCenter
    case doubleCircleWithClosedCenter
    case bigCircle
}

class EuclidCircularSlider : UIControl {
    
    /**
     * Radius of circular slider.
     */
    public var radius = -1.0
    
    public var maxiumumValue = 100.0
    
    public var minimumValue = 0.0
    
    public var lineWidth: Int = 5 {
        didSet {
            self.setNeedsUpdateConstraints()        // This could affect intrinsic content size
            self.invalidateIntrinsicContentSize()   // Need to update intrinsice content size
            self.setNeedsDisplay()                  // Need to redraw with new line width
        }
    }
    
    public var unfilledColor = UIColor.black
    
    public var filledColor = UIColor.red
    
    public var labelFont = UIFont.systemFont(ofSize: 10.0)
    
    public var snapToLabels = false
    
    public var handleType = CircularSliderHandeType.semiTransparentWhiteCircle {
        didSet {
            self.setNeedsUpdateConstraints()        // This could affect intrinsic content size
            self.setNeedsDisplay()                  // Need to redraw with new handle type
        }
    }
    
    public var labelColor = UIColor.red
    
    public var labelDisplacement = 0
    
    public var angleFromNorth = 0
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(withRadius radius: Double) {
        super.init()
        
        self.backgroundColor = UIColor.clear
    }
}
