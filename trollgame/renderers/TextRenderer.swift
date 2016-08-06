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
    
    var message: RenderMessage?
    
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
        createColorPair(.messagePositive, fg: COLOR_WHITE, bg: COLOR_GREEN)
        createColorPair(.messageNegative, fg: COLOR_WHITE, bg: COLOR_RED)
        createColorPair(.wallTile, fg: COLOR_GREEN, bg: COLOR_BLACK)
        createColorPair(.emptyTile, fg: -1, bg: COLOR_BLACK)
        createColorPair(.goalTile, fg: COLOR_MAGENTA, bg: COLOR_BLACK)
        createColorPair(.playerTile, fg: COLOR_CYAN, bg: COLOR_BLACK)
        createColorPair(.trollTile, fg: COLOR_RED, bg: COLOR_BLACK)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TextRenderer.displayMessage(_:)), name: .RendererDisplayMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TextRenderer.hideMessage(_:)), name: .RendererHideMessage, object: nil)
    }
    
    deinit {
        endwin()
        print("Shutting down TextRenderer...")
    }
    
    func render(world: World) {
        // Render level
        for y in 0..<world.vHeight {
            let screenY = y + world.origin.y
            guard screenY >= 0 && screenY < world.lHeight else { continue }
            
            let row = world.matrix[screenY]
            for x in 0..<world.vWidth {
                let screenX = x + world.origin.x
                guard screenX >= 0 && screenX < world.lWidth else { continue }
                
                let char = row[screenX]
                if let tile = Tile(rawValue: char) {
                    withColor(pair: ColorPair(for: tile)) {
                        putChar(y + offset.y, x + offset.x, char)
                    }
                } else {
                    putChar(y + offset.y, x + offset.x, char)
                }
            }
        }
        
        // Render entities
        for entity in world.entities {
            guard world.inViewport(entity.position) else { continue }
            
            // i is row, j is column, but this is reverse of x, y
            let (j, i) = entity.position.tuple
            let tile = entity.currentTile
            withColor(pair: ColorPair(for: tile), {
                putChar(i - world.origin.y + offset.y, j - world.origin.x + offset.x, tile.rawValue)
            })
        }
        
        if let message = message {
            let color: ColorPair
            switch message.type {
            case .positive:
                color = .messagePositive
            case .negative:
                color = .messageNegative
            }
            withColor(pair: color, {
                mvaddstr(Int32(offset.y + 1), Int32(offset.x + world.vWidth / 2 - message.stringMessage.characters.count / 2), message.stringMessage)
            })
        }
        refresh()
    }
    
    @objc func displayMessage(_ notification: Notification) {
        guard let message = notification.object as? RenderMessage else { return }
        self.message = message
    }
    
    @objc func hideMessage(_ notification: Notification) {
        self.message = nil
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
        case messagePositive = 1
        case messageNegative
        case wallTile
        case emptyTile
        case goalTile
        case playerTile
        case trollTile
        
        init(for tile: Tile) {
            switch tile {
            case .wallTile:
                self = .wallTile
            case .emptyTile:
                self = .emptyTile
            case .goalTile:
                self = .goalTile
            case .playerUpTile, .playerDownTile, .playerLeftTile, .playerRightTile:
                self = .playerTile
            case .trollTile:
                self = .trollTile
            case .testUpTile, .testDownTile, .testLeftTile, .testRightTile:
                self = .trollTile
            }
        }
    }
}
