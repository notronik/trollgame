//
//  World.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class World {
    var matrix = [[UnicodeScalar]]()
    var entities = [Entity]()
    
    // Viewport
    let vWidth, vHeight: Int
    var origin: Position = (x: 0, y: 0)
    // Level
    var lWidth, lHeight: Int
    
    init(width: Int, height: Int, string: String) {
        self.vWidth = width
        self.vHeight = height
        
        let components = string.components(separatedBy: .newlines)
        self.lWidth = -1
        self.lHeight = components.count
        for row in components {
            let rowArray = Array(row.unicodeScalars)
            if lWidth < 0 {
                self.lWidth = rowArray.count
            }
            assert(rowArray.count == self.lWidth, "Level width not constant")
            matrix.append(rowArray)
        }
    }
    
    convenience init(width: Int, height: Int, file: URL) throws {
        self.init(width: width, height: height, string: try String(contentsOf: file, encoding: .utf8))
    }
    
    func tile(at position: Position) -> World.Tile {
        return World.Tile(rawValue: matrix[position.y][position.x]) ?? .emptyTile
    }
    
    func inWorld(_ position: Position) -> Bool {
        return position.x >= 0 && position.x < lWidth && position.y >= 0 && position.y < lHeight
    }
    
    func inViewport(_ position: Position) -> Bool {
        return position.x >= origin.x && position.x - origin.x < vWidth && position.y >= origin.y && position.y - origin.y < vHeight
    }
    
    func randomPosition(impassable: [World.Tile]) -> Position {
        let position = (x: Int(arc4random_uniform(UInt32(lWidth))), y: Int(arc4random_uniform(UInt32(lHeight))))
        if inWorld(position) && !impassable.contains(tile(at: position)) {
            return position
        } else {
            return randomPosition(impassable: impassable)
        }
    }
    
    func randomPosition(_ impassable: World.Tile...) -> Position {
        return randomPosition(impassable: impassable)
    }
}

// MARK: World updates -
extension World {
    func update(_ pass: Entity.NominatedPass) {
        for entity in entities {
            entity.update(pass, world: self)
        }
    }
}

// MARK: Extension for tile types
extension World {
    enum Tile: UnicodeScalar {
        case wallTile = "#"
        case emptyTile = " "
        case crossTile = "X"
        case playerUpTile = "^"
        case playerDownTile = "v"
        case playerLeftTile = "<"
        case playerRightTile = ">"
    }
}
