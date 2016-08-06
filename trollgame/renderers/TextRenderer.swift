//
//  TextRenderer.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation
import ncurses
import AppKit.NSColor

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
        _ = noecho()
        
        // Create colors
        createColor(named: .black, #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        createColor(named: .yellow, #colorLiteral(red: 1, green: 0.8901960784, blue: 0, alpha: 1))
        createColor(named: .magenta, #colorLiteral(red: 1, green: 0, blue: 1, alpha: 1))
        createColor(named: .white, #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))
        createColor(named: .gray, #colorLiteral(red: 0.7602152824, green: 0.7601925135, blue: 0.7602053881, alpha: 1))
        createColor(named: .darkGray, #colorLiteral(red: 0.4266758859, green: 0.4266631007, blue: 0.4266703427, alpha: 1))
        createColor(named: .darkGreen, #colorLiteral(red: 0.2193539292, green: 0.7904680172, blue: 0.5820855035, alpha: 1))
        createColor(named: .positive, #colorLiteral(red: 0.4028071761, green: 0.7315050364, blue: 0.2071235478, alpha: 1))
        createColor(named: .negative, #colorLiteral(red: 0.9101451635, green: 0.2575159371, blue: 0.1483209133, alpha: 1))
        
        // Set colors
        createColorPair(.messagePositive, fg: .white, bg: .positive)
        createColorPair(.messageNegative, fg: .white, bg: .negative)
        createColorPair(.wallTile, fg: .gray, bg: .darkGray)
        createColorPair(.emptyTile, fg: .black, bg: .black)
        createColorPair(.goalTile, fg: .magenta, bg: .black)
        createColorPair(.playerTile, fg: .yellow, bg: .black)
        createColorPair(.trollTile, fg: .darkGreen, bg: .black)
        
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
        
        // Render message if there is one
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
    func createColor(named identifier: Color, _ color: NSColor) {
        let red = Int16(color.redComponent * 1000)
        let green = Int16(color.greenComponent * 1000)
        let blue = Int16(color.blueComponent * 1000)
        
        init_color(identifier.rawValue, red, green, blue)
    }
    
    func createColorPair(_ pair: ColorPair, fg: Color, bg: Color) {
        init_pair(pair.rawValue, fg.rawValue, bg.rawValue)
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
    enum Color: Int16 {
        case black = 8
        case yellow
        case magenta
        case white
        case gray
        case darkGray
        case darkGreen
        case positive
        case negative
    }
    
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
