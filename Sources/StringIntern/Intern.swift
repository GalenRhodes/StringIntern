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
#if os(Windows)
    import WinSDK
#endif

@propertyWrapper
public struct Intern {
    static var store: Tree   = Tree()
    static let lock:  NSLock = NSLock()

    let rwLock: ReadWriteLock = ReadWriteLock()
    var item:   ItemCore

    public init(wrappedValue: String) {
        item = Intern.lock.withLock { Intern._store(string: wrappedValue) }
    }

    public var wrappedValue: String {
        get { rwLock.withReadLock { item.string } }
        set { rwLock.withWriteLock { if newValue != item.string { item = Intern.store(item: item, string: newValue) } } }
    }

    static func store(item i: ItemCore, string s: String) -> ItemCore {
        lock.withLock {
            if i.decUse() == 0 { store.remove(key: i.string) }
            return _store(string: s)
        }
    }

    static func _store(string s: String) -> ItemCore {
        if let i = store[s] {
            i.incUse()
            return i
        }
        let i = ItemCore(string: s)
        store.insert(i)
        return i
    }
}

@frozen public struct IntString: CustomStringConvertible, CustomDebugStringConvertible, ExpressibleByStringLiteral, Hashable, Comparable, Codable {

    @Intern public private(set) var string: String

    @inlinable public var description:      String { string }
    @inlinable public var debugDescription: String { string }

    public init(from decoder: Decoder) throws { string = try decoder.singleValueContainer().decode(String.self) }

    public init(stringLiteral value: StringLiteralType) { string = value }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) { string = value }

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) { string = value }

    public init(_ string: String) { self.string = string }

    public init(_ sub: Substring) { string = String(sub) }

    public init<S>(_ sequence: S) where S: Sequence, S.Element == Character { string = String(sequence) }

    public func encode(to encoder: Encoder) throws { var c = encoder.singleValueContainer(); try c.encode(string) }

    @inlinable public func hash(into hasher: inout Hasher) { hasher.combine(string) }

    @inlinable public static func < (lhs: IntString, rhs: IntString) -> Bool { lhs.string < rhs.string }

    @inlinable public static func == (lhs: IntString, rhs: IntString) -> Bool { lhs.string == rhs.string }

    @inlinable public static func == (lhs: String, rhs: IntString) -> Bool { lhs == rhs.string }

    @inlinable public static func == (lhs: IntString, rhs: String) -> Bool { lhs.string == rhs }

    @inlinable public static func < (lhs: String, rhs: IntString) -> Bool { lhs < rhs.string }

    @inlinable public static func < (lhs: IntString, rhs: String) -> Bool { lhs.string < rhs }

    @inlinable public static func <= (lhs: String, rhs: IntString) -> Bool { lhs < rhs || lhs == rhs }

    @inlinable public static func <= (lhs: IntString, rhs: String) -> Bool { lhs < rhs || lhs == rhs }

    @inlinable public static func > (lhs: String, rhs: IntString) -> Bool { !(lhs <= rhs) }

    @inlinable public static func > (lhs: IntString, rhs: String) -> Bool { !(lhs <= rhs) }

    @inlinable public static func >= (lhs: String, rhs: IntString) -> Bool { !(lhs < rhs) }

    @inlinable public static func >= (lhs: IntString, rhs: String) -> Bool { !(lhs < rhs) }

    @inlinable public static func != (lhs: String, rhs: IntString) -> Bool { !(lhs == rhs) }

    @inlinable public static func != (lhs: IntString, rhs: String) -> Bool { !(lhs == rhs) }
}

class ItemCore: Hashable, Comparable {
    let string:   String
    var useCount: UInt64 = 1

    @inlinable init(string: String) { self.string = string }

    @inlinable var key: String { string }
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

    @inlinable func hash(into hasher: inout Hasher) { hasher.combine(string) }

    @inlinable static func < (lhs: ItemCore, rhs: ItemCore) -> Bool { lhs.string < rhs.string }

    @inlinable static func == (lhs: ItemCore, rhs: ItemCore) -> Bool { ((lhs === rhs) || ((type(of: lhs) == type(of: rhs)) && (lhs.string == rhs.string))) }
}

struct Tree {
    var rootNode: TNode? = nil

    @inlinable init() {}

    @inlinable subscript(key: String) -> ItemCore? {
        guard let r = rootNode, let n = r[key] else { return nil }
        return n.item
    }

    @inlinable mutating func insert(_ item: ItemCore) {
        if let r = rootNode { rootNode = r.insert(item: item) }
        else { rootNode = TNode(item: item) }
    }

    @inlinable mutating func remove(key: String) {
        guard let r = rootNode, let n = r[key] else { return }
        rootNode = n.remove()
    }
}

class TNode: Hashable {
    //@f:0
    enum Color: UInt8 { case Black = 0, Red   = 1 }
    enum Side:  Int   { case Left  = 0, Right = 1 }

    private(set) var item: ItemCore
    //@f:1

    @inlinable convenience init(item: ItemCore) {
        self.init(item: item, color: .Black)
    }

    @inlinable init(item: ItemCore, color: Color) {
        self.item = item
        self.color = color
    }

    @inlinable subscript(key: String) -> TNode? { foo(key: key, hit: { $0 }, miss: { _, _ in nil }) }

    @inlinable func insert(item i: ItemCore) -> TNode {
        foo(key: i.key) { n in
            n.item = i
            return n.root
        } miss: { p, sd in
            let n = TNode(item: i, color: .Red)
            p[sd] = n
            return n.postInsert().root
        }!
    }

    func remove() -> TNode? {
        if let l = self[.Left], let r = self[.Right] {
            let other = (Bool.random() ? l.farRight : r.farLeft)
            swap(&item, &other.item)
            return other.remove()
        }
        else if let c = (self[.Left] ?? self[.Right]) {
            c.paintBlack()
            swapWith(node: c)
            return c.root
        }
        else if let p = nodes[2] {
            // A parent but no children.
            if Color.isBlack(self) { preRemove(parent: p) }
            makeOrphan()
            return p.root
        }
        // No children and no parent.
        return nil
    }

    var color: Color
    var nodes: [TNode?] = [ nil, nil, nil ]
}

extension TNode {
    //@f:0
    @inlinable var farLeft:  TNode { ifNil(self[.Left],  yes: { self }, no: { $0.farLeft  }) }
    @inlinable var farRight: TNode { ifNil(self[.Right], yes: { self }, no: { $0.farRight }) }
    @inlinable var root:     TNode { ifNil(nodes[2],     yes: { self }, no: { $0.root     }) }
    //@f:1

    @inlinable subscript(sd: Side) -> TNode? {
        get { nodes[sd.rawValue] }
        set {
            let c = self[sd]
            if c != newValue {
                if let n = c { n.nodes[2] = nil }
                if let n = newValue { n.makeOrphan().nodes[2] = self }
                nodes[sd.rawValue] = newValue
            }
        }
    }

    @discardableResult @inlinable func paintRed() -> TNode { color = .Red; return self }

    @discardableResult @inlinable func paintBlack() -> TNode { color = .Black; return self }

    @discardableResult @inlinable func rotate(direction dir: Side) -> TNode {
        guard let n = self[!dir] else { fatalError(dir == .Left ? ERR_MSG_ROTATE_LEFT : ERR_MSG_ROTATE_RIGHT) }
        swapWith(node: n)
        self[!dir] = n[dir]
        n[dir] = self
        swap(&color, &n.color)
        return self
    }

    @discardableResult @inlinable func makeOrphan() -> TNode { swapWith(node: nil)! }

    @discardableResult @inlinable func swapWith(node n: TNode?) -> TNode? {
        ifNotNil(nodes[2]) { $0[side($0)] = n }
        return n
    }

    @inlinable func side(_ p: TNode) -> Side { ((self === p.self[.Left]) ? .Left : .Right) }

    func foo(key k: String, hit h: (TNode) -> TNode?, miss m: (TNode, Side) -> TNode?) -> TNode? {
        func foo(side sd: Side, key k: String, hit h: (TNode) -> TNode?, miss m: (TNode, Side) -> TNode?) -> TNode? {
            guard let n = self[sd] else { return m(self, sd) }
            return n.foo(key: k, hit: h, miss: m)
        }

        switch k <=> item.key {
            case .Equal:       return h(self)
            case .LessThan:    return foo(side: .Left, key: k, hit: h, miss: m)
            case .GreaterThan: return foo(side: .Right, key: k, hit: h, miss: m)
        }
    }

    func postInsert() -> TNode {
        guard let p = nodes[2] else { return paintBlack() }
        guard Color.isRed(p) else { return self }
        guard let g = p.nodes[2] else { fatalError(ERR_MSG_MISSING_GRAND) }

        let ps = p.side(g)

        if let u = g[!ps], Color.isRed(u) {
            p.paintBlack()
            u.paintBlack()
            return g.paintRed().postInsert()
        }

        if side(p) != ps { p.rotate(direction: ps) }
        g.rotate(direction: !ps)
        return self
    }

    func preRemove(parent p: TNode) {
        let sd = side(p)
        let xd = !sd
        var s  = mustHave(p[xd], ERR_MSG_MISSING_SIBLING)

        if Color.isRed(s) {
            p.rotate(direction: sd)
            s = mustHave(p[xd], ERR_MSG_MISSING_SIBLING)
        }

        if Color.isBlack(s) && Color.isBlack(s[.Left]) && Color.isBlack(s[.Right]) {
            s.paintRed()
            if Color.isRed(p) { p.paintBlack() }
            else if let g = p.nodes[2] { p.preRemove(parent: g) }
        }
        else {
            if Color.isRed(s[sd]) {
                s.rotate(direction: xd)
                s = mustHave(p[xd], ERR_MSG_MISSING_NEPHEW)
            }
            mustHave(s[xd], ERR_MSG_MISSING_NEPHEW).paintBlack()
            p.rotate(direction: sd)
        }
    }

    @inlinable func hash(into hasher: inout Hasher) { hasher.combine(item) }

    @inlinable static func == (lhs: TNode, rhs: TNode) -> Bool { lhs === rhs }
}

extension TNode.Color {
    @inlinable static func isBlack(_ node: TNode?) -> Bool { ((node == nil) || (node!.color == .Black)) }

    @inlinable static func isRed(_ node: TNode?) -> Bool { ((node != nil) && (node!.color == .Red)) }
}

extension TNode.Side {
    @inlinable static prefix func ! (side: Self) -> Self { (side == .Left ? .Right : .Left) }
}

extension NSLock {
    @inlinable func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

class ReadWriteLock {
    #if os(Windows)
        typealias OSRWLock = UnsafeMutablePointer<SRWLOCK>
    #elseif CYGWIN
        typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t?>
    #else
        typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t>
    #endif

    var lock: OSRWLock

    @inlinable init() {
        #if os(Windows)
            lock = OSRWLock.allocate(capacity: 1)
            InitializeSRWLock(lock)
        #else
            lock = OSRWLock.allocate(capacity: 1)
            guard pthread_rwlock_init(lock, nil) == 0 else { fatalError(ERR_MSG_LOCK_INIT_FAILED) }
        #endif
    }

    deinit {
        #if os(Windows)
            lock.deallocate()
        #else
            pthread_rwlock_destroy(lock)
            lock.deallocate()
        #endif
    }
}

extension ReadWriteLock {
    @inlinable func withReadLock<T>(_ body: () throws -> T) rethrows -> T {
        #if os(Windows)
            AcquireSRWLockShared(lock)
            defer { ReleaseSRWLockShared(lock) }
        #else
            guard pthread_rwlock_rdlock(lock) == 0 else { fatalError(ERR_MSG_LOCK_FAILED) }
            defer { pthread_rwlock_unlock(lock) }
        #endif
        return try body()
    }

    @inlinable func withWriteLock<T>(_ body: () throws -> T) rethrows -> T {
        #if os(Windows)
            AcquireSRWLockExclusive(lock)
            defer { ReleaseSRWLockExclusive(lock) }
        #else
            guard pthread_rwlock_wrlock(lock) == 0 else { fatalError(ERR_MSG_LOCK_FAILED) }
            defer { pthread_rwlock_unlock(lock) }
        #endif
        return try body()
    }
}

infix operator <=>: ComparisonPrecedence

@usableFromInline enum ComparisonResults { case LessThan, Equal, GreaterThan }

@inlinable func <=> <T>(left: T?, right: T?) -> ComparisonResults where T: Comparable {
    guard let l = left, let r = right else { return (left == nil ? (right == nil ? .Equal : .LessThan) : .GreaterThan) }
    return (l == r ? .Equal : (l < r ? .LessThan : .GreaterThan))
}

@inlinable func ifNil<T, R>(_ obj: T?, yes: () throws -> R, no: (T) throws -> R) rethrows -> R {
    guard let o = obj else { return try yes() }
    return try no(o)
}

@inlinable func ifNotNil<T>(_ obj: T?, _ yes: (T) throws -> Void) rethrows {
    if let o = obj { try yes(o) }
}

@inlinable func mustHave<T>(_ obj: T?, _ msg: String) -> T {
    guard let o = obj else { fatalError(msg) }
    return o
}
