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
    var origin = Position(x: 0, y: 0)
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
    
    func tile(at position: Position) -> Tile {
        return Tile(rawValue: matrix[position.y][position.x]) ?? .emptyTile
    }
    
    func entity(at position: Position) -> Entity? {
        return (entities.first { (entity) -> Bool in
            entity.position == position
        })
    }
    
    func inWorld(_ position: Position) -> Bool {
        return position.x >= 0 && position.x < lWidth && position.y >= 0 && position.y < lHeight
    }
    
    func inViewport(_ position: Position) -> Bool {
        return position.x >= origin.x && position.x - origin.x < vWidth && position.y >= origin.y && position.y - origin.y < vHeight
    }
    
    func randomPosition(impassable: [Tile]) -> Position {
        let position = Position(x: Int(arc4random_uniform(UInt32(lWidth))), y: Int(arc4random_uniform(UInt32(lHeight))))
        if inWorld(position) && !impassable.contains(tile(at: position)) {
            return position
        } else {
            return randomPosition(impassable: impassable)
        }
    }
    
    func randomPosition(_ impassable: Tile...) -> Position {
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

// MARK: Tile types
enum Tile: UnicodeScalar {
    case wallTile = "#"
    case emptyTile = " "
    case crossTile = "X"
    case playerUpTile = "^"
    case playerDownTile = "v"
    case playerLeftTile = "<"
    case playerRightTile = ">"
    case trollTile = "T"
    case testLeftTile = "L"
    case testRightTile = "R"
    case testUpTile = "U"
    case testDownTile = "D"
}

protocol TileProvider {
    func tile(for direction: Direction) -> Tile
    var containedTiles: [Tile] { get }
}

struct SingleTile: TileProvider {
    let tile: Tile
    
    init(_ tile: Tile) {
        self.tile = tile
    }
    
    func tile(for direction: Direction) -> Tile {
        return self.tile
    }
    
    var containedTiles: [Tile] {
        return [self.tile]
    }
}

struct DirectionalTile: TileProvider {
    let tiles: [Direction: Tile]
    
    init(_ tiles: [Direction: Tile]) {
        self.tiles = tiles
    }
    
    func tile(for direction: Direction) -> Tile {
        return self.tiles[direction] ?? .crossTile
    }
    
    var containedTiles: [Tile] {
        return [tile(for: .up), tile(for: .down), tile(for: .left), tile(for: .right)]
    }
}
