/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: Utils.swift
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

@inlinable func value<T>(_ v: T, isOneOf list: T...) -> Bool where T: Equatable { value(v, isOneOf: list) }

@inlinable func value<T>(_ v: T, isOneOf list: [T]) -> Bool where T: Equatable {
    for _v in list { if v == _v { return true } }
    return false
}

@discardableResult @inlinable func ifNil<T, R1, R2>(_ obj: T?, yes: () throws -> R1, no: (T) throws -> R2) rethrows -> (R1?, R2?) {
    guard let o = obj else { return try (yes(), nil) }
    return try (nil, no(o))
}

@discardableResult @inlinable func ifNotNil<T, R>(_ obj: T?, _ yes: (T) throws -> R) rethrows -> R? {
    guard let o = obj else { return nil }
    return try yes(o)
}

@discardableResult @inlinable func ifThis<R1, R2>(_ predicate: @autoclosure () -> Bool, thenDo this: () throws -> R1, elseDo that: () throws -> R2) rethrows -> (R1?, R2?) {
    try (predicate() ? (this(), nil) : (nil, that()))
}

@inlinable func Q<T>(_ t: (T?, T?)) -> T { (t.0 ?? t.1)! }

infix operator <=>: ComparisonPrecedence

@usableFromInline enum ComparisonResults { case LessThan, Equal, GreaterThan }

@inlinable func <=> <T>(left: T?, right: T?) -> ComparisonResults where T: Comparable {
    ((left == right) ? .Equal : (((right != nil) && ((left == nil) || (left! < right!))) ? .LessThan : .GreaterThan))
}
