//
//  ViewController.swift
//  PositioningFirmwareSUT
//
//  Created by Ivan Kupalov on 04/12/2016.
//  Copyright © 2016 SUT. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    let baseURL = Variable<String>("http://192.168.0.1")
    
    let api: Observable<API>
    let terrain: Observable<Terrain>
    
    let canvas = UIImageView()
    let coorinatesView = UILabel()
    let changeAddressButton = UIButton()
    
    let disposeBag = DisposeBag()
    
    init() {
        api = baseURL.asObservable().map { url -> API in
            return APIImpl(baseURL: url)
        }
        
        terrain = api.asObservable().flatMapLatest { api in
            api.getTerrain().catchErrorJustReturn(Terrain(sizeX: 1, sizeY: 1))
        }
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
        canvas.widthAnchor.constraint(equalTo: canvas.heightAnchor).isActive = true
        
        canvas.layer.borderWidth = 1
        canvas.layer.borderColor = UIColor.lightGray.cgColor
        
        coorinatesView.font = UIFont.systemFont(ofSize: 20)
        coorinatesView.textAlignment = .center
        view.addSubview(coorinatesView)
        coorinatesView.translatesAutoresizingMaskIntoConstraints = false
        coorinatesView.topAnchor.constraint(equalTo: canvas.bottomAnchor, constant: 20).isActive = true
        coorinatesView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        coorinatesView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        
        view.addSubview(changeAddressButton)
        changeAddressButton.translatesAutoresizingMaskIntoConstraints = false
        
        changeAddressButton.topAnchor.constraint(equalTo: coorinatesView.bottomAnchor).isActive = true
        changeAddressButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        changeAddressButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        baseURL.asObservable().bindTo(changeAddressButton.rx.title(for: .normal)).addDisposableTo(disposeBag)
        changeAddressButton.setTitleColor(UIColor.blue, for: .normal)

        changeAddressButton.rx.tap.subscribe(onNext: {
            self.openChangeAddressAlert()
        })
        .addDisposableTo(disposeBag)
    
        let gestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)
        canvas.addGestureRecognizer(gestureRecognizer)
        canvas.isUserInteractionEnabled = true

        
        Observable<Int>.interval(1.0, scheduler: MainScheduler.instance)
            .withLatestFrom(api.asObservable())
            .flatMapLatest { api in api.getLocation().catchErrorJustReturn(Point(x: 0, y: 0)) }
            .withLatestFrom(terrain) { ($0, $1) }
            .debug()
            .subscribe(onNext: { (point, terrain) in
                self.drawCanvas(terrain: terrain, point: point)
                self.coorinatesView.text = "x: \(point.x), y: \(point.y)"
            })
            .addDisposableTo(disposeBag)
        
        gestureRecognizer.rx.event
            .withLatestFrom(terrain) { ($0, $1) }
            .withLatestFrom(api.asObservable()) { ($0.0, $0.1, $1) }
            .flatMap { (recongnizer, terrain, api) -> Observable<Void> in
                let location = recongnizer.location(in: self.canvas)
                let x = location.x / self.canvas.frame.maxX * CGFloat(terrain.sizeX)
                let y = location.y / self.canvas.frame.maxY * CGFloat(terrain.sizeY)
                print("Sending to: \(x) \(y)")
                return api.postLocation(point: Point(x: Double(x),
                                                          y: Double(y)))
                    .catchErrorJustReturn(())
            }
            .debug()
            .subscribe()
            .addDisposableTo(disposeBag)
    }
    
    typealias LineCoordinates = (CGPoint, CGPoint)
    typealias RulerLabel = (CGRect, String)
    typealias RulerPoint = (line: LineCoordinates, label: RulerLabel)

    private func drawCanvas(terrain: Terrain, point: Point) {
        
        let horizontalStep = canvas.frame.maxX / CGFloat(terrain.sizeX)
        let xIndicies = 1..<terrain.sizeX
        let horizontalPoints = xIndicies.map { (i: Int) -> RulerPoint in
            let x = CGFloat(i) * horizontalStep
            let lineStart = CGPoint(x: x, y: 0)
            let lineEnd = CGPoint(x: x, y: 20)
            
            let labelFrame = CGRect(x: x + 5, y: 5, width: 20, height: 20)
            return (line: (lineStart, lineEnd), label: (labelFrame, "\(i)"))
        }
        
        let verticalStep = canvas.frame.maxY / CGFloat(terrain.sizeY)
        let yIndicies = 1...terrain.sizeY
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
        
        let pointX = canvas.frame.maxX / CGFloat(terrain.sizeX) * CGFloat(point.x)
        let pointY = canvas.frame.maxY / CGFloat(terrain.sizeY) * CGFloat(point.y)
        drawPoint(context: context, x: pointX, y: pointY)
        
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
    
    private func drawPoint(context: CGContext, x: CGFloat, y: CGFloat) {
        context.setFillColor(UIColor.blue.cgColor)
        context.setStrokeColor(UIColor.blue.cgColor)
        context.setLineWidth(5)
        
        let position = CGRect(x: x, y: y, width: 10, height: 10)
        context.addEllipse(in: position)
        context.drawPath(using: .fillStroke)
    }
    
    private func openChangeAddressAlert() {
        let alert = UIAlertController(title: "Change Address", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Base URL"
            field.clearButtonMode = .whileEditing
            field.textColor = .blue
            field.text = self.baseURL.value
        }
        alert.addAction(UIAlertAction(title: "Change", style: .default) { _ in
            let field = alert.textFields?.first!
            self.baseURL.value = field?.text ?? ""
        })
        present(alert, animated: true, completion: nil)
    }
}

