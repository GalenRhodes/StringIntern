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

@inlinable func ifNil<T, R>(_ obj: T?, yes: () throws -> R, no: (T) throws -> R) rethrows -> R {
    guard let o = obj else { return try yes() }
    return try no(o)
}

@inlinable func ifNotNil<T>(_ obj: T?, _ yes: (T) throws -> Void) rethrows {
    if let o = obj { try yes(o) }
}

@inlinable func ifThis(_ predicate: @autoclosure () -> Bool, thenDo this: () throws -> Void, elseDo that: () throws -> Void) rethrows {
    if predicate() { try this() }
    else { try that() }
}

infix operator <=>: ComparisonPrecedence

@usableFromInline enum ComparisonResults { case LessThan, Equal, GreaterThan }

@inlinable func <=> <T>(left: T?, right: T?) -> ComparisonResults where T: Comparable {
    ((left == right) ? .Equal : (((right != nil) && ((left == nil) || (left! < right!))) ? .LessThan : .GreaterThan))
}

@inlinable func mustHave<T>(_ obj: T?, _ msg: String) -> T {
    guard let o = obj else { fatalError(msg) }
    return o
}

@usableFromInline typealias SwitchCase<R> = () throws -> R
@usableFromInline typealias CaseSet<T: Equatable, R> = (value: T, action: SwitchCase<R>)

@inlinable func inlineSwitch<T: Equatable, R>(_ sw: T, cases: CaseSet<T, R>..., default def: SwitchCase<R>) rethrows -> R {
    for sc in cases { if sw == sc.value { return try sc.action() } }
    return try def()
}
