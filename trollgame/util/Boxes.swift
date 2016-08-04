//
//  Boxes.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class GenericBox<T>: NSObject {
    let data: T
    init(_ data: T) {
        self.data = data
    }
}
