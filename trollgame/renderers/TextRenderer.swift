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
    var hadHideable = false
    
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
        createColor(named: .black,      #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        createColor(named: .yellow,     #colorLiteral(red: 1, green: 0.8901960784, blue: 0, alpha: 1))
        createColor(named: .magenta,    #colorLiteral(red: 1, green: 0, blue: 1, alpha: 1))
        createColor(named: .white,      #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))
        createColor(named: .gray,       #colorLiteral(red: 0.7602152824, green: 0.7601925135, blue: 0.7602053881, alpha: 1))
        createColor(named: .darkGray,   #colorLiteral(red: 0.4266758859, green: 0.4266631007, blue: 0.4266703427, alpha: 1))
        createColor(named: .darkGreen,  #colorLiteral(red: 0.2193539292, green: 0.7904680172, blue: 0.5820855035, alpha: 1))
        createColor(named: .lightRed,   #colorLiteral(red: 0.8949507475, green: 0.5508074871, blue: 0.5237553709, alpha: 1))
        createColor(named: .positive,   #colorLiteral(red: 0.4028071761, green: 0.7315050364, blue: 0.2071235478, alpha: 1))
        createColor(named: .negative,   #colorLiteral(red: 0.9101451635, green: 0.2575159371, blue: 0.1483209133, alpha: 1))
        
        // Set colors
        createColorPair(.messagePositive, fg: .white, bg: .positive)
        createColorPair(.messageNegative, fg: .white, bg: .negative)
        createColorPair(.messageInformation, fg: .black, bg: .yellow)
        createColorPair(.wallTile, fg: .gray, bg: .darkGray)
        createColorPair(.bloodiedWallTile, fg: .lightRed, bg: .darkGray)
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
                if let tile = Tile(value: char) {
                    let pair: ColorPair
                    if !Tile.isAttributed(char) {
                        pair = ColorPair(for: tile)
                    } else {
                        switch tile {
                        case .wallTile:
                            pair = .bloodiedWallTile
                        default:
                            pair = ColorPair(for: tile)
                        }
                    }
                    
                    withColor(pair: pair) {
                        putChar(y + offset.y, x + offset.x, char)
                    }
                } else {
                    putChar(y + offset.y, x + offset.x, char)
                }
            }
        }
        
        // Render entities
        for entity in world.entities.values {
            guard world.inViewport(entity.position) else { continue }
            
            // i is row, j is column, but this is reverse of x, y
            let (j, i) = entity.position.tuple
            let tile = entity.currentTile
            withColor(pair: ColorPair(for: tile), {
                putChar(i - world.origin.y + offset.y, j - world.origin.x + offset.x, tile.value)
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
            case .information:
                color = .messageInformation
            }
            
            let msgY: Int32
            // transient and info messages display at the bottom of the screen
            if message.transient || message.type == .information {
                msgY = Int32(offset.y + world.vHeight)
                move(msgY, 0)
                clrtoeol()
            } else {
                msgY = Int32(offset.y + 1)
            }
            
            withColor(pair: color, {
                mvaddstr(msgY, Int32(offset.x + world.vWidth / 2 - message.stringMessage.characters.count / 2), message.stringMessage)
            })
            
            if message.transient {
                self.hadHideable = true
                self.message = nil
            }
        } else if hadHideable {
            hadHideable = false // clear area of transient message
            move(Int32(offset.y + world.vHeight), 0)
            clrtoeol()
        }
        
        refresh()
    }
    
    @objc func displayMessage(_ notification: Notification) {
        guard let message = notification.object as? RenderMessage else { return }
        self.message = message
    }
    
    @objc func hideMessage(_ notification: Notification) {
        guard let message = self.message else { return }
        if message.transient || message.type == .information {
            self.hadHideable = true
        }
        
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
    
    func putChar(_ row: Int, _ col: Int, _ char: UInt32) {
        mvaddch(Int32(row), Int32(col), char)
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
        case lightRed
        case positive
        case negative
    }
    
    enum ColorPair: Int16 {
        case messagePositive = 1
        case messageNegative
        case messageInformation
        case wallTile
        case bloodiedWallTile
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
            }
        }
    }
}
