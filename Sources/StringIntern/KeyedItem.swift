/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: KeyedItem.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/17/21
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

protocol KeyedItem: Hashable {
    associatedtype K where K: Comparable

    var key:    K { get }
    var item:   ItemCore { get }
    var index:  UInt64 { get }
    var string: String { get }
}

struct Item<T: Comparable>: KeyedItem {
    typealias K = T

    let item: ItemCore

    init(item: ItemCore) { self.item = item }
}

extension KeyedItem {
    @inlinable var index:  UInt64 { item.index }
    @inlinable var string: String { item.string }

    @inlinable func hash(into hasher: inout Hasher) { hasher.combine(item) }

    @inlinable static func == (lhs: Self, rhs: Self) -> Bool { lhs.item == rhs.item }

    @inlinable var key: K { ((type(of: K.self) == type(of: UInt64.self) ? item.index as! K : item.string as! K)) }
}
