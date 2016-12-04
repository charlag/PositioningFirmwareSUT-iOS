//
//  ViewController.swift
//  PositioningFirmwareSUT
//
//  Created by Ivan Kupalov on 04/12/2016.
//  Copyright © 2016 SUT. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let canvas = UIImageView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(canvas)
        canvas.translatesAutoresizingMaskIntoConstraints = false
        canvas.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        canvas.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        canvas.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        canvas.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        drawCanvas()
    }
    
    typealias LineCoordinates = (CGPoint, CGPoint)
    typealias RulerLabel = (CGRect, String)
    typealias RulerPoint = (line: LineCoordinates, label: RulerLabel)

    private func drawCanvas() {
        let horizontalSize = 10
        let verticalSize = 20
        
        let horizontalStep = canvas.frame.maxX / CGFloat(horizontalSize)
        let xIndicies = 1..<horizontalSize
        let horizontalPoints = xIndicies.map { (i: Int) -> RulerPoint in
            let x = CGFloat(i) * horizontalStep
            let lineStart = CGPoint(x: x, y: 0)
            let lineEnd = CGPoint(x: x, y: 20)
            
            let labelFrame = CGRect(x: x + 5, y: 5, width: 20, height: 20)
            return (line: (lineStart, lineEnd), label: (labelFrame, "\(i)"))
        }
        
        let verticalStep = canvas.frame.maxY / CGFloat(verticalSize)
        let yIndicies = 1..<verticalSize
        let verticalPoints = yIndicies.map { i -> RulerPoint in
            let y = CGFloat(i) * verticalStep
            let lineStart = CGPoint(x: 0, y: y)
            let lineEnd = CGPoint(x: 20, y: y)
            
            let labelFrame = CGRect(x: 5, y: y - 25, width: 20, height: 20)
            return (line: (lineStart, lineEnd), label: (labelFrame, "\(i)"))
        }
        
        UIGraphicsBeginImageContext(canvas.frame.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(2)
        context.setFillColor(UIColor.black.cgColor)
        
        drawRuler(context: context, elements: horizontalPoints)
        drawRuler(context: context, elements: verticalPoints)
        
        
        canvas.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    private func drawRuler(context: CGContext, elements: [RulerPoint]) {
        
        for element in elements {
            let (lineStart, lineEnd) = element.line
            context.move(to: lineStart)
            context.addLine(to: lineEnd)
            context.strokePath()
            
            let (labelRect, labelText) = element.label
            ("\(labelText)" as NSString).draw(in: labelRect,
                                      withAttributes: nil)
        }
    }

}

