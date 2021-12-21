/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: IntString.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/21/21
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

@frozen public struct IntString: CustomStringConvertible, CustomDebugStringConvertible, ExpressibleByStringLiteral, Hashable, Comparable {
    @Intern public private(set) var string: String

    @inlinable public var description:      String { string }
    @inlinable public var debugDescription: String { string }

    public init(stringLiteral value: StringLiteralType) { string = value }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) { string = value }

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) { string = value }

    public init(_ string: String) { self.string = string }

    public init(_ sub: Substring) { string = String(sub) }

    public init<S>(_ sequence: S) where S: Sequence, S.Element == Character { string = String(sequence) }

    public func hash(into hasher: inout Hasher) { hasher.combine(_string) }

    public static func < (lhs: IntString, rhs: IntString) -> Bool { lhs._string < rhs._string }

    public static func == (lhs: IntString, rhs: IntString) -> Bool { lhs._string == rhs._string }
}

public func == (lhs: String, rhs: IntString) -> Bool { lhs == rhs.string }

public func == (lhs: IntString, rhs: String) -> Bool { lhs.string == rhs }

public func < (lhs: String, rhs: IntString) -> Bool { lhs < rhs.string }

public func < (lhs: IntString, rhs: String) -> Bool { lhs.string < rhs }

public func <= (lhs: String, rhs: IntString) -> Bool { lhs < rhs || lhs == rhs }

public func <= (lhs: IntString, rhs: String) -> Bool { lhs < rhs || lhs == rhs }

public func > (lhs: String, rhs: IntString) -> Bool { !(lhs <= rhs) }

public func > (lhs: IntString, rhs: String) -> Bool { !(lhs <= rhs) }

public func >= (lhs: String, rhs: IntString) -> Bool { !(lhs < rhs) }

public func >= (lhs: IntString, rhs: String) -> Bool { !(lhs < rhs) }

public func != (lhs: String, rhs: IntString) -> Bool { !(lhs == rhs) }

public func != (lhs: IntString, rhs: String) -> Bool { !(lhs == rhs) }

