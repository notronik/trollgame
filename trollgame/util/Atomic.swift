//
//  Atomic.swift
//  trollgame
//
//  Created by Nik on 03/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation
import Darwin.C.stdatomic

class AtomicFlag {
    private var backing: atomic_flag = atomic_flag()
    
    init(_ initial: Bool) {
        if initial {
            testAndSet()
        } else {
            clear()
        }
    }
    
    /// Test-and-set while returning the previous value
    @discardableResult
    func testAndSet() -> Bool {
        return atomic_flag_test_and_set(&backing)
    }
    
    func clear() {
        atomic_flag_clear(&backing)
    }
}
