//
//  Stack.swift
//  trollgame
//
//  Created by Nik on 05/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

struct Stack<Element> {
    private var items: [Element]
    
    init() {
        self.items = []
    }
    
    init(array: [Element]) {
        self.items = array
    }
    
    mutating func push(item: Element) {
        items.append(item)
    }
    
    mutating func pop() -> Element {
        return items.removeLast()
    }
    
    var topItem: Element? {
        return items.last
    }
    
    var isEmpty: Bool {
        return items.isEmpty
    }
}
