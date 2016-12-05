//
//  API.swift
//  PositioningFirmwareSUT
//
//  Created by Ivan Kupalov on 04/12/2016.
//  Copyright © 2016 SUT. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import RxAlamofire


struct Terrain {
    let sizeX: Int
    let sizeY: Int
}

struct Point {
    let x: Double
    let y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    init(json: [String: Any]) {
        self.init(x: json["x"] as! Double,
                  y: json["y"] as! Double)
    }
    
    func asJSON() -> [String: Any] {
        return ["x": x,
                "y": y]
    }
}

protocol API {
    func getTerrain() -> Observable<Terrain>
    func getLocation() -> Observable<Point>
    func postLocation(point: Point) -> Observable<Void>
}

enum APIError: Error {
    case InvalidAnswerError
}

struct APIImpl: API {
    
    let baseURL = "http://78.155.217.162:5858"
    let terrainPath: String
    let locationPath: String
    
    init() {
        terrainPath = baseURL + "/terrain"
        locationPath = baseURL + "/point"
    }
    
    func getTerrain() -> Observable<Terrain> {
        return RxAlamofire.requestJSON(.get, terrainPath).map { (response, JSON) -> Terrain in
            guard let JSONData = JSON as? [String: AnyObject] else {
                throw APIError.InvalidAnswerError
            }
            return Terrain(sizeX: JSONData["sizeX"] as! Int, sizeY: JSONData["sizeY"] as! Int)
        }
        .debug()
    }
    
    func getLocation() -> Observable<Point> {
        return RxAlamofire.json(.get, locationPath)
            .map { json in
                Point(json: json as! [String: Any])
            }
            .debug()
    }
    
    func postLocation(point: Point) -> Observable<Void> {
        return RxAlamofire.json(.post, locationPath, parameters: point.asJSON(), encoding: JSONEncoding.default)
            .map { _ in Void() }
            .debug()
    }
}
