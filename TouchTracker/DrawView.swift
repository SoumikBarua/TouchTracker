//
//  DrawView.swift
//  TouchTracker
//
//  Created by SB on 11/30/18.
//  Copyright © 2018 SB. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate {
    var currentLines = [NSValue:Line]()
    var currentCircle = [NSValue:Circle]()
    var finishedLines = [Line]()
    var finishedCircles = [Circle]()
    var selectedLineIndex: Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    var longPressRecognizer: UILongPressGestureRecognizer!
    var moveRecognizer: UIPanGestureRecognizer!
    
    @IBInspectable var finishedLinesColor: UIColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLinesColor: UIColor = UIColor.red {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickness: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var finishedCirclesColor: UIColor = UIColor.orange {
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentCircleColor: UIColor = UIColor.gray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func stroke(_ line: Line) {
        let path = UIBezierPath()
        path.lineWidth = lineThickness
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    func fill(_ circle: Circle) {
        var originX: CGFloat
        var originY: CGFloat
        if circle.cornerOneEnd.x <= circle.cornerTwoEnd.x {
            originX = circle.cornerOneEnd.x
        } else {
            originX = circle.cornerTwoEnd.x
        }
        if circle.cornerOneEnd.y <= circle.cornerTwoEnd.y {
            originY = circle.cornerOneEnd.y
        } else {
            originY = circle.cornerTwoEnd.y
        }
        let originPoint = CGPoint(x: originX, y: originY)
        
        let circleSize: CGSize
        let circleWidth = fabs(circle.cornerOneEnd.x-circle.cornerTwoEnd.x)
        let circleHeight = fabs(circle.cornerOneEnd.y-circle.cornerTwoEnd.y)
        if circleWidth <= circleHeight {
            circleSize = CGSize(width: circleWidth, height: circleWidth)
        } else {
            circleSize = CGSize(width: circleHeight, height: circleHeight)
        }
        
        let customRect = CGRect(origin: originPoint, size: circleSize)
        
        let path = UIBezierPath(ovalIn: customRect)
        path.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        // Draw finished lines in black
        finishedLinesColor.setStroke()
        for line in finishedLines {
            stroke(line)
        }
        
        // Draw current lines in red
        currentLinesColor.setStroke()
        for (_, line) in currentLines {
            stroke(line)
        }
        
        // Make the colored of the selected line green
        if let index = selectedLineIndex {
            UIColor.green.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
        }
        
        // Draw finished circles in purple
        finishedCirclesColor.setStroke()
        for circle in finishedCircles {
            fill(circle)
        }
        
        // Draw current cicle in grey
        currentCircleColor.setStroke()
        for (_, circle) in currentCircle {
            fill(circle)
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        if event?.allTouches?.count == 2 {
            var cornerOneLocation, cornerTwoLocation: CGPoint?
            let key = NSValue(nonretainedObject: touches.first)
            for (i, touch) in touches.enumerated() {
                if i == 0 {
                    cornerOneLocation = touch.location(in: self)
                } else {
                    cornerTwoLocation = touch.location(in: self)
                }
            }
            let newCircle = Circle(cornerOneBegin: cornerOneLocation!, cornerOneEnd: cornerOneLocation!, cornerTwoBegin: cornerTwoLocation!, cornerTwoEnd: cornerTwoLocation!)
            
            currentCircle[key] = newCircle
            
        } else {
            for touch in touches {
                let location = touch.location(in: self)
                
                let newLine = Line(begin: location, end: location)
                
                let key = NSValue(nonretainedObject: touch)
                currentLines[key] = newLine
            }
        }
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        
        if event?.allTouches?.count == 2 {
            // For circles
            let key = NSValue(nonretainedObject: touches.first)
            
            for (i, touch) in touches.enumerated() {
                if i == 0 {
                    currentCircle[key]?.cornerOneEnd = touch.location(in: self)
                } else {
                    currentCircle[key]?.cornerTwoEnd = touch.location(in: self)
                }
            }
        } else {
            
            // For lines
            for touch in touches {
                let key = NSValue(nonretainedObject: touch)
                currentLines[key]?.end = touch.location(in: self)
                
                let beginX = currentLines[key]?.begin.x
                let beginY = currentLines[key]?.begin.y
                let endX = currentLines[key]?.end.x
                let endY = currentLines[key]?.end.y
                if (Float(beginX!) < Float(endX!)) && (Float(beginY!) > Float(endY!)) {
                    currentLinesColor = UIColor.blue
                } else if (Float(beginX!) > Float(endX!)) && (Float(beginY!) > Float(endY!)) {
                    currentLinesColor = UIColor.red
                } else if (Float(beginX!) < Float(endX!)) && (Float(beginY!) < Float(endY!)) {
                    currentLinesColor = UIColor.yellow
                } else {
                    currentLinesColor = UIColor.green
                }
            }
        }
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        
        if event?.allTouches?.count == 2 {
            // For circles
            let key = NSValue(nonretainedObject: touches.first)
            
            for (i, touch) in touches.enumerated() {
                if i == 0 {
                    currentCircle[key]?.cornerOneEnd = touch.location(in: self)
                } else {
                    currentCircle[key]?.cornerTwoEnd = touch.location(in: self)
                }
            }
            finishedCircles.append(currentCircle[key]!)
            currentCircle.removeAll()
        } else {
            // For lines
            for touch in touches {
                let key = NSValue(nonretainedObject: touch)
                if var line = currentLines[key] {
                    line.end = touch.location(in: self)
                    
                    finishedLines.append(line)
                    currentLines.removeValue(forKey: key)
                }
            }
        }
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Log statement to see the order of events
        print(#function)
        
        currentCircle.removeAll()
        currentLines.removeAll()
        
        setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        addGestureRecognizer(longPressRecognizer)
        
        moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DrawView.moveLine(_:)))
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
    }
    
    @objc func doubleTap(_ gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a double tap")
        
        currentLines.removeAll()
        finishedLines.removeAll()
        finishedCircles.removeAll()
        selectedLineIndex = nil
        setNeedsDisplay()
    }
    
    @objc func tap(_ gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a tap!")
        
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLine(at: point)
        
        // Grab the menu controller
        let menu = UIMenuController.shared
        
        if selectedLineIndex != nil {
            // Make DrawView the target of menu item action messages
            becomeFirstResponder()
            
            // Create a new "Delete" UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(DrawView.deleteLine(_:)))
            menu.menuItems = [deleteItem]
            
            // Tell the menu where it should come from and show it
            let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self)
            menu.setMenuVisible(true, animated: true)
        } else {
            // Hide the menu if no line was selected
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    func indexOfLine(at point: CGPoint) -> Int? {
        // Find a line close to point
        for (index, line) in finishedLines.enumerated() {
            let begin = line.begin
            let end = line.end
            
            // Check a few points on the line
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                // If the tapped point is within 20 points, let's return this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                    return index
                }
            }
        }
        // If nothing is close enough to the tapped point, then we did not select a line
        return nil
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc func deleteLine(_ sender: UIMenuController) {
        // Remove the selected line from the list of finishedLines
        if let index = selectedLineIndex {
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            
            // Redraw
            setNeedsDisplay()
        }
    }
    
    @objc func longPress(_ gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a long press")
        
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll()
            }
        } else if gestureRecognizer.state == .ended {
            selectedLineIndex = nil
        }
        setNeedsDisplay()
    }
    
    @objc func moveLine(_ gestureRecognizer: UIPanGestureRecognizer) {
        print("Recognized a pan")
        //print("pan speed is \(moveRecognizer.velocity(in: self))")
        //print("x value is \(moveRecognizer.velocity(in: self).x)")
        
        guard longPressRecognizer.state == .changed else {
            return
        }
        
        // If a line is seelcted
        if let index = selectedLineIndex {
            // When the pan recognizer changes its position
            if gestureRecognizer.state == .changed {
                // How far has the pan moved?
                let translation = gestureRecognizer.translation(in: self)
                
                // Add the translation to the current beginning and end points of the line
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                gestureRecognizer.setTranslation(CGPoint.zero, in: self)
                
                // Redraw the screen
                setNeedsDisplay()
            }
        } else {
            return
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
