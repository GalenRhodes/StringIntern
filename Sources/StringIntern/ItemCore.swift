/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: ItemCore.swift
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

@usableFromInline class ItemCore: Hashable, Comparable {
    @usableFromInline let index:    UInt64
    @usableFromInline let string:   String
    @usableFromInline var useCount: UInt64 = 1

    @usableFromInline init(index: UInt64 = 0, string: String) {
        self.index = index
        self.string = string
    }
}

extension ItemCore {
    @discardableResult @inlinable func incUse() -> UInt64 {
        useCount += 1
        return useCount
    }

    @discardableResult @inlinable func decUse() -> UInt64 {
        if useCount > 0 { useCount -= 1 }
        return useCount
    }

    @inlinable func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        hasher.combine(string)
    }

    @inlinable static func < (lhs: ItemCore, rhs: ItemCore) -> Bool { lhs.string < rhs.string }

    @inlinable static func == (lhs: ItemCore, rhs: ItemCore) -> Bool { ((lhs === rhs) || ((type(of: lhs) == type(of: rhs)) && (lhs.string == rhs.string))) }
}
