//
//  TextRenderer.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation
import ncurses

class TextRenderer: Renderer {
    let offset: Position
    
    init (offset: Position) {
        self.offset = offset
        
        // Ensure that we return the terminal back to a useable state even after sigint.
        trap(signal: .INT) {_ in
            endwin()
            exit(0)
        }
        
        // maybe trap winch as well for window size change
        
        initscr()
        curs_set(0)
        start_color()
        use_default_colors()
        _ = noecho()
        
        // Set colors
        createColorPair(.wallTile, fg: COLOR_GREEN, bg: COLOR_BLACK)
        createColorPair(.emptyTile, fg: -1, bg: COLOR_BLACK)
        createColorPair(.crossTile, fg: COLOR_MAGENTA, bg: COLOR_BLACK)
        createColorPair(.playerTile, fg: COLOR_RED, bg: COLOR_BLACK)
    }
    
    deinit {
        endwin()
        print("Shutting down TextRenderer...")
    }
    
    func render(world: World) {
        for y in 0..<world.vHeight {
            let screenY = y + world.origin.y
            guard screenY >= 0 && screenY < world.lHeight else { continue }
            
            let row = world.matrix[screenY]
            for x in 0..<world.vWidth {
                let screenX = x + world.origin.x
                guard screenX >= 0 && screenX < world.lWidth else { continue }
                
                let char = row[screenX]
                if let tile = World.Tile(rawValue: char) {
                    withColor(pair: ColorPair.color(for: tile)) {
                        putChar(y + offset.y, x + offset.x, char)
                    }
                } else {
                    putChar(y + offset.y, x + offset.x, char)
                }
            }
        }
        for entity in world.entities {
            guard world.inViewport(entity.position) else { continue }
            
            // i is row, j is column, but this is reverse of x, y
            let (j, i) = entity.position
            withColor(pair: ColorPair.color(for: entity.tile), {
                putChar(i - world.origin.y + offset.y, j - world.origin.x + offset.x, entity.tile.rawValue)
            })
        }
        refresh()
    }
}

// MARK: Utility functions -
extension TextRenderer {
    func createColorPair(_ pair: ColorPair, fg: Int32, bg: Int32) {
        init_pair(pair.rawValue, Int16(fg), Int16(bg))
    }
    
    func withColor(pair: ColorPair, _ block: @noescape () -> Void) {
        attron(COLOR_PAIR(Int32(pair.rawValue)))
        block()
        attroff(COLOR_PAIR(Int32(pair.rawValue)))
        use_default_colors()
    }
    
    func putChar(_ row: Int, _ col: Int, _ char: UnicodeScalar) {
        mvaddch(Int32(row), Int32(col), char.value)
    }
}

// MARK: Utility constants -
extension TextRenderer {
    enum ColorPair: Int16 {
        case wallTile = 1
        case emptyTile
        case crossTile
        case playerTile
        
        static func color(for tile: World.Tile) -> ColorPair {
            switch tile {
            case .wallTile:
                return .wallTile
            case .emptyTile:
                return .emptyTile
            case .crossTile:
                return .crossTile
            case .playerUpTile, .playerDownTile, .playerLeftTile, .playerRightTile:
                return .playerTile
            }
        }
    }
}
