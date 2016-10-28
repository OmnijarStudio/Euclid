/**
    Copyright (c) 2016 Omnijar Studio
 
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
 
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
 
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
 */

import UIKit


/// Slider attributes for styling and drawing.
public enum EuclidSliderAttributes {
    /* Track */
    case maximumTrackTint(UIColor)
    case minimumTrackTint(UIColor)
    case trackShadowDepth(Float)
    case trackShadowRadius(Float)
    case trackMaxAngle(Double)
    case trackMinAngle(Double)
    case trackWidth(Float)
    
    /* Thumb */
    case hasThumb(Bool)
    case thumbRadius(Float)
    case thumbShadowDepth(Float)
    case thumbShadowRadius(Float)
    case thumbTint(UIColor)
    case thumbImage(UIImage)
}

/// Slider handles
public enum EuclidSliderHandleType {
    case semiTransparentWhiteCircle
    case semiTransparentBlackCircle
    case doubleCircleWithOpenCenter
    case doubleCircleWithClosedCenter
    case bigCircle
}

/// Circular slider control for iOS.
@IBDesignable
open class EuclidSlider : UIControl {
    
    // MARK: Public Properties
    
    /// The value of the element.
    @IBInspectable
    public var value: Float = 0.5 {
        didSet {
            let cappedVal = cappedValue(value)
            
            if value != cappedVal {
                value = cappedVal
            }
            
            setNeedsDisplay()
            
            sendActions(for: .valueChanged)
        }
    }
    
    /// The minimum value of the slider.
    @IBInspectable
    public var valueMinimum: Float = 0 {
        didSet {
            value = cappedValue(value)
            setNeedsDisplay()
        }
    }
    
    /// The maximum value of the slider.
    @IBInspectable
    public var valueMaximum: Float = 1 {
        didSet {
            value = cappedValue(value)
            setNeedsDisplay()
        }
    }
    
    // MARK: Internal Properties
    
    /// The non-selected tint for the circular track.
    @IBInspectable
    var minimumTrackTint: UIColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
    
    /// The selected tint for the circular track.
    @IBInspectable
    var maximumTrackTint: UIColor = UIColor(red: 0.71, green: 0.71, blue: 0.71, alpha: 1.0)
    
    /// The width of the track.
    @IBInspectable
    var trackWidth: Float = 2 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The radius of the track's shadow.
    @IBInspectable
    var trackShadowRadius: Float = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The depth of the track's shadow.
    @IBInspectable
    var trackShadowDepth: Float = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The minimum angle of the track.
    @IBInspectable
    var trackMinAngle: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The maximum angle of the track.
    @IBInspectable
    var trackMaxAngle: Double = 360.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Designates whether to use the thumb element.
    @IBInspectable
    var hasThumb: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The tint of the thumb element.
    @IBInspectable
    var thumbTint: UIColor = UIColor.white
    
    /// The radius of the thumb element.
    @IBInspectable
    var thumbRadius: Float = 14 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The radius of the thumb shadow.
    @IBInspectable
    var thumbShadowRadius: Float = 2 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The depth of the thumb shadow.
    @IBInspectable
    var thumbShadowDepth: Float = 3 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The image of the thumb.
    @IBInspectable
    var thumbImage: UIImage? = UIColor.white.toImage()
    {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: Private Properties
    
    /// The thumb layer.
    private var thumbLayer = CALayer()
    
    /// The thumb mask.
    private var thumbMask = CAShapeLayer()
    
    /// The center of the view.
    private var viewCenter: CGPoint {
        return convert(center, from: superview)
    }
    
    /// The center of the thumb.
    private var thumbCenter: CGPoint {
        var thumbCenter = viewCenter
        thumbCenter.x += CGFloat(cos(thumbAngle) * controlRadius)
        thumbCenter.y += CGFloat(sin(thumbAngle) * controlRadius)
        
        return thumbCenter
    }
    
    /// The radius of the control.
    private var controlRadius: Float {
        return Float(min(bounds.width, bounds.height)) / 2.0 - controlThickness
    }
    
    /// The thickness of the control.
    private var controlThickness: Float {
        let thumbRadius = (hasThumb) ? self.thumbRadius : 0
        return max(thumbRadius, trackWidth / 2.0)
    }
    
    /// The innter radius of the control.
    private var innerControlRadius: Float {
        return controlRadius - trackWidth * 0.5
    }
    
    /// The outer radius of the control.
    private var outerControlRadius: Float {
        return controlRadius + trackWidth * 0.5
    }
    
    /// The angle of the thumb.
    private var thumbAngle: Float {
        let normalizedValue = (value - valueMinimum) / (valueMaximum - valueMinimum)
        let degrees = Double(normalizedValue) * (trackMaxAngle - trackMinAngle) +
        trackMinAngle
        // Convert to radians and rotate 180 degrees so that 0 degrees would be on
        // the left.
        let radians = degrees / 180.0 * M_PI + M_PI
        
        return Float(radians)
    }
    
    /// The last position for touch.
    private var lastPositionForTouch = CGPoint(x: 0, y: 0)
    
    /// The pseudo value for touch.
    private var pseudoValueForTouch = Float(0.0)
    
    /// The center of the control.
    override open var center: CGPoint {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: Intializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        prepare()
    }
    
    /**
        Initializes the control with the specified
        radius.
    */
    init(withRadius radius: Double) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        self.backgroundColor = UIColor.clear
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        prepare()
    }
    
    // MARK: Public Methods
    
    override open func prepareForInterfaceBuilder() {
        prepare()
    }
    
    override open func draw(_ rect: CGRect) {
        /**
            Returns a UIBezierPath with the shape of a ring slice.
         
            - Parameters:
                - arcCenter:   The center of the ring
                - innerRadius: The inner radius of the ring
                - outerRadius: The outer radius of the ring
                - startAngle:  The start angle of the ring slice
                - endAngle:    The end angle of the ring slice
         
            - Returns: A `UIBezierPath` with the shape of a ring slice.
         */
        func getArcPath(arcCenter: CGPoint, innerRadius: Float,
                        outerRadius: Float, startAngle: Float,
                        endAngle: Float) -> UIBezierPath {
            
            let arcPath = UIBezierPath(arcCenter:   arcCenter,
                                       radius:      CGFloat(outerRadius),
                                       startAngle:  CGFloat(startAngle),
                                       endAngle:    CGFloat(endAngle),
                                       clockwise:   true)
            
            arcPath.addArc(withCenter: viewCenter,
                                     radius:        CGFloat(innerRadius),
                                     startAngle:    CGFloat(endAngle),
                                     endAngle:      CGFloat(startAngle),
                                     clockwise:     false)
            arcPath.close()
            
            return arcPath
        }
        
        /**
            Clips the drawing to the EuclidSlider track.
         */
        func clipPath() {
            let minAngle = Float(trackMinAngle / 180.0 * M_PI + M_PI)
            let maxAngle = Float(trackMaxAngle / 180.0 * M_PI + M_PI)
            let clipPath = getArcPath(arcCenter:    viewCenter,
                                      innerRadius:  innerControlRadius,
                                      outerRadius:  outerControlRadius,
                                      startAngle:   minAngle,
                                      endAngle:     maxAngle)
            
            clipPath.addClip()
        }
        
        /**
            Fills the part of the track between the mininum angle and the thumb.
         */
        func drawProgress() {
            let minAngle = Float(trackMinAngle / 180.0 * M_PI + M_PI)
            
            let progressPath = getArcPath(arcCenter:    viewCenter,
                                          innerRadius:  innerControlRadius,
                                          outerRadius:  outerControlRadius,
                                          startAngle:   minAngle,
                                          endAngle:     thumbAngle)
            
            minimumTrackTint.setFill()
            progressPath.fill()
        }
        
        /**
            Sets the shadow.
         
            - Parameters:
                - context: Context of the shadow.
                - depth: Depth of the shadow.
                - radius: Radius of the shadow.
        */
        func setShadow(context: CGContext, depth: CGFloat, radius: CGFloat) {
            context.clip(to: CGRect.infinite)
            context.setShadow(offset: CGSize(width: 0, height: depth), blur: radius)
        }
        
        /**
            Draws the track.
         
            - Parameters:
                - context: Context of the track.
        */
        func drawTrack(context: CGContext) {
            let trackPath = circlePath(withCenter: viewCenter,
                                       radius: CGFloat(outerControlRadius))
            maximumTrackTint.setFill()
            trackPath.fill()
            
            if trackShadowDepth > 0 {
                setShadow(context: context, depth: CGFloat(trackShadowDepth), radius: CGFloat(trackShadowRadius))
            }
            
            let trackShadowPath = UIBezierPath(rect: CGRect.infinite)
            
            trackShadowPath.append(
                circlePath(withCenter: viewCenter,
                           radius: CGFloat(outerControlRadius + 0.5))
            )
            
            trackShadowPath.close()
            
            trackShadowPath.append(
                circlePath(withCenter: viewCenter,
                           radius: CGFloat(innerControlRadius - 0.5))
            )
            
            trackShadowPath.usesEvenOddFillRule = true
            
            UIColor.black.set()
            trackShadowPath.fill()
        }
        
        /**
            Draw the thumb component of the control.
        */
        func drawThumb() {
            let thumbPath = circlePath(withCenter:  thumbCenter,
                                       radius:      CGFloat(thumbRadius))
            
            let thumbHasShadow = thumbShadowDepth != 0 || thumbShadowRadius != 0
            
            if hasThumb && thumbHasShadow {
                thumbMask.path = thumbPath.cgPath
                thumbMask.fillColor = thumbTint.cgColor
                
                thumbMask.shadowColor = UIColor.black.cgColor
                thumbMask.shadowPath = thumbPath.cgPath
                thumbMask.shadowOffset = CGSize(width: 0, height: Int(thumbShadowDepth))
                thumbMask.shadowOpacity = 0.25
                thumbMask.shadowRadius = CGFloat(thumbShadowRadius)
                
            } else {
                thumbMask.path = nil
                thumbMask.shadowPath = nil
                
                if hasThumb {
                    thumbTint.setFill()
                    thumbPath.fill()
                }
            }
        }
        
        let context = UIGraphicsGetCurrentContext()
        context!.saveGState()
        
        clipPath()
        
        drawTrack(context: context!)
        
        context!.restoreGState()
        
        drawProgress()
        
        drawThumb()
    }
    
    override open func beginTracking(_ touch: UITouch,
                                     with event: UIEvent?) -> Bool {
        // TODO: Add an inactive touch option for read-only thumb positioning.

        if hasThumb {
            let location = touch.location(in: self)
            
            let pseudoValue = calculatePseudoValue(at: location)
            // Check if the touch is out of our bounds.
            if cappedValue(pseudoValue) != pseudoValue {
                // If the touch is on the thumb, start dragging from the thumb.
                if locationOnThumb(location: location) {
                    lastPositionForTouch = location
                    let _ = calculatePseudoValue(at: thumbCenter)
                    return true
                    
                } else {
                    // Not on thumb or track, so abort gesture.
                    return false
                }
            }
            
            value = pseudoValue
            lastPositionForTouch = location
        }
        
        return super.beginTracking(touch, with: event)
    }
    
    override open func continueTracking(_ touch: UITouch,
                                          with event: UIEvent?) -> Bool {
        // TODO: Add an inactive touch option for read-only thumb positioning.
        if !hasThumb {
            return super.continueTracking(touch, with: event)
        }
        
        let location = touch.location(in: self)
        
        value = calculatePseudoValue(from: lastPositionForTouch, to: location)
        
        lastPositionForTouch = location
        
        return true
    }
    
    /**
        Iterate over the provided attributes and set the corresponding values.
        
        - Parameters: 
            - attributes: Styling & drawing attributes for the slider.
    */
    public func configure(attributes: [EuclidSliderAttributes]) {
        for attribute in attributes {
            switch attribute {
                /* Track */
            case let .minimumTrackTint(value):
                self.minimumTrackTint = value
            case let .maximumTrackTint(value):
                self.maximumTrackTint = value
            case let .trackWidth(value):
                self.trackWidth = value
            case let .trackShadowRadius(value):
                self.trackShadowRadius = value
            case let .trackShadowDepth(value):
                self.trackShadowDepth = value
            case let .trackMinAngle(value):
                self.trackMinAngle = value
            case let .trackMaxAngle(value):
                self.trackMaxAngle = value
                
                /* Thumb */
            case let .hasThumb(value):
                self.hasThumb = value
            case let .thumbTint(value):
                self.thumbTint = value
            case let .thumbRadius(value):
                self.thumbRadius = value
            case let .thumbShadowRadius(value):
                self.thumbShadowRadius = value
            case let .thumbShadowDepth(value):
                self.thumbShadowDepth = value
            case let .thumbImage(value):
                self.thumbImage = value
            }
        }
        
        setNeedsDisplay()
    }
    
    // MARK: Private Methods
    
    /**
        Prepare the control.
    */
    private func prepare() {
        contentMode = .redraw
        isOpaque = false
        backgroundColor = .clear
        
        layer.insertSublayer(thumbMask, at: 0)
    }
    
    /**
        Returns the capped value.
     
        - Parameters:
            - value: Value to cap.
     
        - Returns: Capped value.
    */
    private func cappedValue(_ value: Float) -> Float {
        return min(max(valueMinimum, value), valueMaximum)
    }
    
    /**
        Generates the circle path to be used when drawing.
     
        - Parameters: 
            - center: Center to draw around.
            - radius: Radius of the circle.
     
        - Returns: Bezier path to draw.
    */
    private func circlePath(withCenter center: CGPoint,
                            radius: CGFloat) -> UIBezierPath {
        return UIBezierPath(arcCenter: center,
                            radius: radius,
                            startAngle: 0,
                            endAngle: CGFloat(M_PI * 2.0),
                            clockwise: true)
    }
    
    /**
        Identifies of the provided location is on the thumb.
     
        - Parameters:
            - location: Location of the thumb.
     
        - Returns: True if the provided location is on the thumb, 
                   false otherwise.
    */
    private func locationOnThumb(location: CGPoint) -> Bool {
        let thumbCenter = self.thumbCenter
        return sqrt(pow(location.x - thumbCenter.x, 2) +
            pow(location.y - thumbCenter.y, 2)) <= CGFloat(thumbRadius)
    }
    
    /**
        Calculates the pseudo value.
     
        - Parameters: 
            - point: Point of the angle.
     
        - Returns: The pseudo value.
    */
    private func calculatePseudoValue(at point: CGPoint) -> Float {
        let angle = angleAt(point: point)
        
        // Normalize the angle, then convert to value scale.
        let targetValue =
            Float(angle / (trackMaxAngle - trackMinAngle)) *
                (valueMaximum - valueMinimum) + valueMinimum
        
        pseudoValueForTouch = targetValue
        
        return targetValue
    }
    
    /**
        Calculates the pseudo value, given the source and
        destination points.
     
        - Parameters: 
            - from: Origin point.
            - to: Destination point.
     
        - Returns: The pseudo value.
    */
    private func calculatePseudoValue(from: CGPoint, to: CGPoint) -> Float {
        let angle1 = angleAt(point: from)
        let angle2 = angleAt(point: to)
        var angle = angle2 - angle1
        let valueRange = valueMaximum - valueMinimum
        let angleToValue =
            Double(valueRange) / (trackMaxAngle - trackMinAngle)
        let clockwise = isClockwise(
            vector1: CGPoint(x: from.x - bounds.midX, y: from.y - bounds.midY),
            vector2: CGPoint(x: to.x - from.x, y: to.y - from.y)
        )
        
        if (clockwise) {
            while (angle < 0) { angle += 360 }
            
        } else {
            while (angle > 0) { angle -= 360 }
        }
        
        // Update our value by as much as the last motion defined.
        pseudoValueForTouch += Float(angle * angleToValue)
        
        // And make sure we don't count more than one whole circle of overflow.
        if (pseudoValueForTouch > valueMinimum + valueRange * 2) {
            pseudoValueForTouch -= valueRange
        }
        if (pseudoValueForTouch < valueMinimum - valueRange) {
            pseudoValueForTouch += valueRange
        }
        
        return pseudoValueForTouch
    }
    
    /**
        Checks if the slider is clockwise.
     
        - Parameters: 
            - vector1: Vector point of the origin.
            - vector2: Vector point of the destination.
     
        - Returns: True of the slider is moving clockwise, false otherwise.
    */
    private func isClockwise(vector1: CGPoint, vector2: CGPoint) -> Bool {
        return vector1.y * vector2.x < vector1.x * vector2.y
    }
    
    /**
        Gets the angle at a point.
     
        - Parameters:
            - point: Point to check the angle.
     
        - Returns: The angle of the point provided.
    */
    private func angleAt(point: CGPoint) -> Double {
        // Calculate the relative angle of the user's touch point starting from
        // trackMinAngle.
        var angle = (Double(atan2(point.x - bounds.midX, point.y - bounds.midY)) /
            M_PI * 180.0 + trackMinAngle) + 180
        angle = (90 - angle) .truncatingRemainder(dividingBy: 360)
        while (angle < 0) { angle += 360 }
        
        return angle
    }
}

/**
    Extension to the `UIColor` object to support generating an
    `UIImage` from a color.
 */
extension UIColor {
    func toImage() -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        self.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
