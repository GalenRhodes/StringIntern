/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: Intern.swift
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

@propertyWrapper
public struct Intern: Hashable, Comparable {
    @usableFromInline static var store: Tree<Item> = Tree()
    @usableFromInline static let lock:  NSLock     = NSLock()

    @usableFromInline let rwLock: ReadWriteLock = ReadWriteLock()
    @usableFromInline var item:   ItemCore

    public init(wrappedValue: String) {
        item = Intern.lock.withLock { Intern.store(string: wrappedValue) }
    }

    public var wrappedValue: String {
        get { rwLock.withReadLock { item.string } }
        set { rwLock.withWriteLock { if newValue != item.string { item = Intern.store(item: item, string: newValue) } } }
    }

    @inlinable static func store(item i: ItemCore, string s: String) -> ItemCore {
        lock.withLock {
            if i.decUse() == 0 { store.remove(key: i.string) }
            return store(string: s)
        }
    }

    @inlinable static func store(string s: String) -> ItemCore {
        if let i = store[s]?.item {
            i.incUse()
            return i
        }
        let i = ItemCore(string: s)
        store.insert(Item(item: i))
        return i
    }

    @inlinable public func hash(into hasher: inout Hasher) { rwLock.withReadLock { hasher.combine(item) } }

    @inlinable public static func < (lhs: Intern, rhs: Intern) -> Bool { lhs.rwLock.withReadLock { rhs.rwLock.withReadLock { lhs.item < rhs.item } } }

    @inlinable public static func == (lhs: Intern, rhs: Intern) -> Bool { lhs.rwLock.withReadLock { rhs.rwLock.withReadLock { lhs.item == rhs.item } } }
}

extension NSLock {
    @inlinable func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
