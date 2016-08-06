//
//  World.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class World {
    var matrix = [[UInt32]]()
    var entities = [UUID: Entity]()
    
    // Viewport
    let vWidth, vHeight: Int
    var origin = Position(x: 0, y: 0)
    // Level
    var lWidth, lHeight: Int
    
    /// Create a World with a specific viewport size from a level string
    init(width: Int, height: Int, string: String) {
        self.vWidth = width
        self.vHeight = height
        
        let components = string.components(separatedBy: .newlines)
        self.lWidth = -1
        self.lHeight = components.count
        for row in components {
            let rowArray = Array(row.unicodeScalars.map { $0.value })
            if lWidth < 0 {
                self.lWidth = rowArray.count
            }
            assert(rowArray.count == self.lWidth, "Level width not constant")
            matrix.append(rowArray)
        }
    }
    
    /// Create a World with a specific viewport size from a level file
    convenience init(width: Int, height: Int, file: URL) throws {
        self.init(width: width, height: height, string: try String(contentsOf: file, encoding: .utf8))
    }
    
    /// Create a World with a specific viewport size by generating a maze
    init(width: Int, height: Int, mazeWidth: Int, mazeHeight: Int, xCellSize: Int = 3, yCellSize: Int = 1, wallSize: Int = 1) {
        assert(mazeWidth % 2 == 1, "Maze width must be odd")
        assert(mazeHeight % 2 == 1, "Maze height must be odd")
        assert(xCellSize % 2 == 1, "Horizontal cell size must be odd")
        assert(yCellSize % 2 == 1, "Vertical cell size must be odd")
        
        self.vWidth = width
        self.vHeight = height
        self.lWidth = mazeWidth
        self.lHeight = mazeHeight
        
        // *** *** *** *** *** ***
        
        let xCellNum = mazeWidth / (xCellSize + wallSize)
        let yCellNum = mazeHeight / (yCellSize + wallSize)
        let numberCells = xCellNum * yCellNum
        
        func transformToMatrix(cell position: Position) -> Position {
            return Position(x: (xCellSize + wallSize) / 2 + (xCellSize + wallSize) * position.x,
                            y: (yCellSize + wallSize) / 2 + (yCellSize + wallSize) * position.y)
        }
        
        var visited = [Position]() // in cell coordinates
        // Generate the maze from a random cell
        var current = Position(x: Int(arc4random_uniform(UInt32(xCellNum))), y: Int(arc4random_uniform(UInt32(yCellNum))))
        var backtrackStack = Stack<Position>()
        
        /// Get the neigbor of a specific position
        func neighbor(_ position: Position, _ direction: Direction) -> Position {
            return position + direction.deltaPosition
        }
        
        /// Obtain the unvisited neighbours of the cell or nil if no neighbours are unvisited
        func unvisitedNeighbors(_ position: Position)  -> [Position]? {
            var neighbors = [Position]()
            
            for direction in Direction.cases {
                let nbr = neighbor(position, direction)
                // Ensure that neighbour is unvisited and in level
                guard !visited.contains(nbr),
                    nbr.x >= 0 && nbr.x < xCellNum,
                    nbr.y >= 0 && nbr.y < yCellNum else {
                        continue
                }
                neighbors.append(nbr)
            }
            
            return neighbors.isEmpty ? nil : neighbors
        }
        
        // Initialise the level matrix
        self.matrix = Array<[UInt32]>(repeating: Array<UInt32>(repeating: Tile.wallTile.value, count: mazeWidth), count: mazeHeight)
        for j in 0..<yCellNum {
            for i in 0..<xCellNum {
                let cellPos = transformToMatrix(cell: Position(x: i, y: j))
                
                // Clear area of cell
                for sy in -(yCellSize/2)...(yCellSize/2) {
                    for sx in -(xCellSize/2)...(xCellSize/2) {
                        matrix[cellPos.y + sy][cellPos.x + sx] = Tile.emptyTile.value
                    }
                }
            }
        }
        
        /// Carve a path between two cell locations
        func carvePath(from: Position, to: Position) {
            guard let direction = Direction(delta: to - from) else { return }
            
            let tFrom = transformToMatrix(cell: from)
            let tTo = transformToMatrix(cell: to)
            
            switch direction {
            case .up, .down:
                let middle = Position(x: tFrom.x, y: (tTo.y + tFrom.y) / 2)
                for sy in -(wallSize / 2)...(wallSize / 2) {
                    for sx in -(xCellSize / 2)...(xCellSize / 2) {
                        matrix[middle.y + sy][middle.x + sx] = Tile.emptyTile.value
                    }
                }
            case .left, .right:
                let middle = Position(x: (tTo.x + tFrom.x) / 2, y: tFrom.y)
                for sy in -(yCellSize / 2)...(yCellSize / 2) {
                    for sx in -(wallSize / 2)...(wallSize / 2) {
                        matrix[middle.y + sy][middle.x + sx] = Tile.emptyTile.value
                    }
                }
            }
        }
        
        // Generation loop
        while visited.count < numberCells {
            if let neighbors = unvisitedNeighbors(current) {
                // Choose a random unvisited neighbour
                let neighbor = neighbors.random()
                
                // Push the current cell to the stack
                backtrackStack.push(item: current)
                
                // Remove the wall between the current and chosen cell
                carvePath(from: current, to: neighbor)
                
                // Make the chosen cell the current cell
                current = neighbor
                // Mark as visited
                visited.append(current)
            } else if !backtrackStack.isEmpty {
                // Backtrack by making previous cell current cell
                current = backtrackStack.pop()
            }
        }
        
        // Place the exit
        let edge = Direction.random() // udlr analogous to tblr
        
        let exitCell: Position
        let neighborCell: Position
        let exitPosition: Position
        switch edge {
        case .up, .down:
            exitCell = Position(x: Int(arc4random_uniform(UInt32(xCellNum))), y: edge == .up ? 0 : yCellNum - 1)
            neighborCell = neighbor(exitCell, edge)
            exitPosition = Position(x: transformToMatrix(cell: exitCell).x,
                                    y: (transformToMatrix(cell: exitCell).y + transformToMatrix(cell: neighborCell).y) / 2)
        case .left, .right:
            exitCell = Position(x: edge == .left ? 0 : xCellNum - 1, y: Int(arc4random_uniform(UInt32(yCellNum))))
            neighborCell = neighbor(exitCell, edge)
            exitPosition = Position(x: (transformToMatrix(cell: exitCell).x + transformToMatrix(cell: neighborCell).x) / 2,
                                    y: transformToMatrix(cell: exitCell).y)
        }
        
        carvePath(from: exitCell, to: neighbor(exitCell, edge))
        matrix[exitPosition.y][exitPosition.x] = Tile.goalTile.value
    }
    
    func tile(at position: Position) -> Tile {
        return Tile(value: matrix[position.y][position.x]) ?? .emptyTile
    }
    
    func entities(at position: Position, excluding: [Entity] = []) -> [Entity]? {
        if entities.isEmpty {
            return nil
        }
        
        return entities.values.filter { (entity) in
            return entity.position == position && !excluding.contains { entity == $0 }
        }
    }
    
    func firstEntity(at position: Position) -> Entity? {
        return (entities.values.first { (entity) -> Bool in
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
        // Position only accepted if the position is valid, does not contain impassable tiles, and does not contain entities.
        if inWorld(position) && !impassable.contains(tile(at: position)) && firstEntity(at: position) == nil {
            return position
        } else {
            return randomPosition(impassable: impassable)
        }
    }
    
    func randomPosition(_ impassable: Tile...) -> Position {
        return randomPosition(impassable: impassable)
    }
    
    func add(entity: Entity) {
        entity.world = self
        self.entities[entity.id] = entity
    }
    
    func removeEntity(entity: Entity) {
        removeEntity(id: entity.id)
    }
    
    func removeEntity(id: UUID) {
        self.entities.removeValue(forKey: id)
    }
}

// MARK: World updates -
extension World {
    func update(_ pass: Entity.NominatedPass) {
        for (_, entity) in entities {
            entity.update(pass, world: self)
        }
    }
}

// MARK: Tile types -
enum Tile: UnicodeScalar {
    case wallTile =         "#"
    case emptyTile =        " "
    case goalTile =         "X"
    case playerUpTile =     "^"
    case playerDownTile =   "v"
    case playerLeftTile =   "<"
    case playerRightTile =  ">"
    case trollTile =        "T"

    init?(value: UInt32) {
        if let tile = Tile(rawValue: UnicodeScalar(Tile.removeAttribute(value))) {
            self = tile
        } else {
            return nil
        }
    }
    
    var value: UInt32 {
        return self.rawValue.value
    }
    
    var attributed: UInt32 {
        return self.rawValue.value | (1 << 31)
    }
    
    static func removeAttribute(_ value: UInt32) -> UInt32 {
        return value & ~(1 << 31)
    }
    
    static func isAttributed(_ value: UInt32) -> Bool {
        return (value >> 31) & 0b1 == 0b1
    }
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
        return self.tiles[direction] ?? .goalTile
    }
    
    var containedTiles: [Tile] {
        return [tile(for: .up), tile(for: .down), tile(for: .left), tile(for: .right)]
    }
}
