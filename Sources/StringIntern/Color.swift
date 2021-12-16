/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: Color.swift
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

enum Color {
    case Black
    case Red
}

extension Color {
    @inlinable static func isBlack<K, T>(_ node: TNode<K, T>?) -> Bool where K: Comparable, T: KeyedItem<K> { ((node == nil) || (node!.color == .Black)) }

    @inlinable static func isRed<K, T>(_ node: TNode<K, T>?) -> Bool where K: Comparable, T: KeyedItem<K> { ((node != nil) && (node!.color == .Red)) }
}
