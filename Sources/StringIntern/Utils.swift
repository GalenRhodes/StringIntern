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

func value<T>(_ v: T, isOneOf list: T...) -> Bool where T: Equatable { value(v, isOneOf: list) }

func value<T>(_ v: T, isOneOf list: [T]) -> Bool where T: Equatable {
    for _v in list { if v == _v { return true } }
    return false
}

func ifNil<T>(_ obj: T?, yes: () throws -> Void, no: (T) throws -> Void) rethrows {
    if let o = obj { try no(o) }
    else { try yes() }
}

func ifNotNil<T>(_ obj: T?, _ yes: (T) throws -> Void) rethrows {
    if let o = obj { try yes(o) }
}

func ifThis(_ predicate: @autoclosure () -> Bool, thenDo this: () throws -> Void, elseDo that: () throws -> Void) rethrows {
    if predicate() { try this() }
    else { try that() }
}

infix operator <=>: ComparisonPrecedence

enum ComparisonResults { case LessThan, Equal, GreaterThan }

func <=> <T>(left: T?, right: T?) -> ComparisonResults where T: Comparable {
    ((left == right) ? .Equal : (((right != nil) && ((left == nil) || (left! < right!))) ? .LessThan : .GreaterThan))
}

@inlinable func mustHave<T>(_ obj: T?, _ msg: String) -> T {
    guard let o = obj else { fatalError(msg) }
    return o
}
