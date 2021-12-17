/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: StringIntern.swift
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
public struct Intern {
    private static var byIndex:   Tree<Item<UInt64>> = Tree()
    private static var byString:  Tree<Item<String>> = Tree()
    private static let rwLock:    ReadWriteLock      = ReadWriteLock()
    private static var nextIndex: UInt64             = 0

    private var index: UInt64 = 0

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }

    public var wrappedValue: String {
        get {
            Intern.rwLock.withReadLock {
                guard let str = Intern.byIndex[index]?.item.string else { fatalError("Interned string not found.") }
                return str
            }
        }
        set {
            Intern.rwLock.withWriteLock {
                if index > 0, let item = Intern.byIndex[index]?.item {
                    guard newValue != item.string else { return }
                    item.useCount -= 1

                    if item.useCount <= 0 {
                        Intern.byIndex.remove(key: item.index)
                        Intern.byString.remove(key: item.string)
                    }
                }
                if let item = Intern.byString[newValue]?.item {
                    index = item.index
                    item.useCount += 1
                }
                else {
                    index = Intern.nextIndex + 1
                    Intern.nextIndex = index
                    let item = ItemCore(index: index, string: newValue)
                    Intern.byIndex.insert(Item<UInt64>(item: item))
                    Intern.byString.insert(Item<String>(item: item))
                }
            }
        }
    }
}
