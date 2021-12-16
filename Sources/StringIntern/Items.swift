/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: Items.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/15/21
 *
 * Copyright © 2021. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation

class ItemCore: Hashable {
    let index:    UInt64
    let string:   String
    var useCount: Int = 0

    init(index: UInt64, string: String) {
        self.index = index
        self.string = string
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        hasher.combine(string)
    }

    static func == (lhs: ItemCore, rhs: ItemCore) -> Bool {
        ((lhs === rhs) || ((type(of: lhs) == type(of: rhs)) && (lhs.index == rhs.index) && (lhs.string == rhs.string)))
    }
}

class KeyedItem<K>: Hashable where K: Comparable {

    var key:  K { fatalError() }
    let item: ItemCore

    init(index: UInt64, string: String) {
        item = ItemCore(index: index, string: string)
    }

    init(item: ItemCore) { self.item = item }

    func hash(into hasher: inout Hasher) {
        hasher.combine(item)
    }

    static func == (lhs: KeyedItem<K>, rhs: KeyedItem<K>) -> Bool {
        ((lhs === rhs) || ((type(of: lhs) == type(of: rhs)) && (lhs.item == rhs.item)))
    }
}

class IndexItem: KeyedItem<UInt64> {
    override var key: UInt64 { item.index }
}

class StringItem: KeyedItem<String> {
    override var key: String { item.string }
}
