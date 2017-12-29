//
//  GraphView.swift
//  Calc
//
//  Created by admin on 13.11.2017.
//  Copyright © 2017 Ivan Bolgov. All rights reserved.
//

import UIKit
@IBDesignable
class GraphView: UIView {

    var yForX :((Double) -> Double)? { didSet { setNeedsDisplay() } }
    
    @IBInspectable
    var scale: CGFloat = 50.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var lineWidth: CGFloat = 2.0 { didSet { setNeedsDisplay() } }
    @IBInspectable
    var color: UIColor = UIColor.red { didSet { setNeedsDisplay() } }
    @IBInspectable
    var colorAxes: UIColor = UIColor.black { didSet { setNeedsDisplay() } }
    
    var originSet: CGPoint? { didSet { setNeedsDisplay() } }
    
    private var origin: CGPoint {
        get {
            return originSet ?? CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        }
        set {
            originSet = newValue
        }
    }
    
    private var axesDrawer = AxesDrawer()
    
    override func draw(_ rect: CGRect) {
        axesDrawer.contentScaleFactor = contentScaleFactor
        axesDrawer.color = colorAxes
        axesDrawer.drawAxes(in: bounds, origin: origin, pointsPerUnit: scale)
        drawCurveInRect(bounds, origin: origin, scale: scale)
    }
    
    func drawCurveInRect(_ bounds:CGRect, origin: CGPoint, scale: CGFloat) {
        var xGraph, yGraph :CGFloat
        var x, y: Double
        var isFirstPoint = true
        
        var oldGraph :CGFloat = 0.0
        var disContinuty :Bool{
            return abs(yGraph - oldGraph) > max(bounds.width, bounds.height) * 1.5
        }
        
        if yForX != nil {
            color.set()
            let path = UIBezierPath()
            path.lineWidth = lineWidth
            yGraph = 0.0
            for i in 0...Int(bounds.size.width * contentScaleFactor) {
                xGraph = CGFloat(i) / contentScaleFactor
                x = Double((xGraph - origin.x) / scale)
                
                y = (yForX)!(x)
                
                guard y.isFinite else { continue }
                oldGraph = yGraph
                yGraph = origin.y - CGFloat(y) * scale
                if isFirstPoint {
                    path.move(to: CGPoint(x: xGraph, y: yGraph))
                    isFirstPoint = false
                }
                else {
                    if disContinuty {
                        isFirstPoint = true
                    } else {
                        path.addLine(to: CGPoint(x: xGraph, y: yGraph))
                    }
                }
            }
            path.stroke()
        }
    }
    
    @objc func scale(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            scale *= gesture.scale
            gesture.scale = 1.0
        }
    }
    
    @objc func origin(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            origin = gesture.location(in: self)
        }
    }
    
    @objc func originMove(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .ended:
            fallthrough
        case .changed:
            let translation = gesture.translation(in: self)
            if translation != CGPoint.zero {
                origin.x += translation.x
                origin.y += translation.y
                gesture.setTranslation(CGPoint.zero, in: self)
            }
        default:
            break
        }
    }
}
