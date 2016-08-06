//
//  Utility.swift
//  trollgame
//
//  Created by Nik on 05/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

func flattenTileProviders(_ providers: [TileProvider]) -> Set<Tile> {
    return Set<Tile>(providers.map({ (provider) -> [Tile] in
        provider.containedTiles
    }).flatten())
}

extension Array {
    func random() -> Element {
        return self[Int(arc4random_uniform(UInt32(self.count)))]
    }
}
