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

    @usableFromInline typealias OSRWLock = UnsafeMutablePointer<SRWLOCK>
    @usableFromInline typealias OSThreadKey = DWORD
#elseif CYGWIN
    @usableFromInline typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t?>
    @usableFromInline typealias OSThreadKey = pthread_key_t
#else
    @usableFromInline typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t>
    @usableFromInline typealias OSThreadKey = pthread_key_t
#endif

@propertyWrapper
public struct Intern {
    @usableFromInline static var store: Tree<ItemCore> = Tree()
    @usableFromInline static let lock:  NSLock         = NSLock()

    @usableFromInline let rwLock: ReadWriteLock = ReadWriteLock()
    @usableFromInline var item:   ItemCore

    @inlinable public init(wrappedValue: String) {
        item = Intern.lock.withLock { Intern._store(string: wrappedValue) }
    }

    @inlinable public var wrappedValue: String {
        get { rwLock.withReadLock { item.string } }
        set { rwLock.withWriteLock { if newValue != item.string { item = Intern.store(item: item, string: newValue) } } }
    }

    @inlinable static func store(item i: ItemCore, string s: String) -> ItemCore {
        lock.withLock {
            if i.decUse() == 0 { store.remove(key: i.string) }
            return _store(string: s)
        }
    }

    @inlinable static func _store(string s: String) -> ItemCore {
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

    @inlinable public func encode(to encoder: Encoder) throws { var c = encoder.singleValueContainer(); try c.encode(string) }

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

@usableFromInline class ItemCore: Hashable, Comparable, KeyedItem {
    @usableFromInline typealias K = String

    @usableFromInline let string:   String
    @usableFromInline var useCount: UInt64 = 1

    @inlinable init(string: String) {
        self.string = string
    }

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

extension NSLock {
    @inlinable func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

@usableFromInline class ReadWriteLock {
    @usableFromInline var lock: OSRWLock

    @inlinable init() {
        lock = OSRWLock.allocate(capacity: 1)
        #if os(Windows)
            InitializeSRWLock(lock)
        #else
            guard pthread_rwlock_init(lock, nil) == 0 else { fatalError("Unable to initialize read/write lock.") }
        #endif
    }

    deinit {
        #if !os(Windows)
            pthread_rwlock_destroy(lock)
        #endif
        lock.deallocate()
    }
}

extension ReadWriteLock {

    @inlinable func withReadLock<T>(_ body: () throws -> T) rethrows -> T {
        #if os(Windows)
            AcquireSRWLockShared(lock)
            defer { ReleaseSRWLockShared(lock) }
        #else
            guard pthread_rwlock_rdlock(lock) == 0 else { fatalError("Unknown Error.") }
            defer { pthread_rwlock_unlock(lock) }
        #endif
        return try body()
    }

    @inlinable func withWriteLock<T>(_ body: () throws -> T) rethrows -> T {
        #if os(Windows)
            AcquireSRWLockExclusive(lock)
            defer { ReleaseSRWLockExclusive(lock) }
        #else
            guard pthread_rwlock_wrlock(lock) == 0 else { fatalError("Unknown Error.") }
            defer { pthread_rwlock_unlock(lock) }
        #endif
        return try body()
    }
}

let                   ERR_MSG_PFX:             String = "Internal Inconsistency Error"
let                   ERR_MSG_MISSING_GRAND:   String = "\(ERR_MSG_PFX): Missing Grandparent"
let                   ERR_MSG_MISSING_SIBLING: String = "\(ERR_MSG_PFX): Missing Sibling"
let                   ERR_MSG_MISSING_NEPHEW:  String = "\(ERR_MSG_PFX): Missing Distant Nephew"
@usableFromInline let ERR_MSG_ROTATE_LEFT:     String = "\(ERR_MSG_PFX): Cannot rotate left - no right child node."
@usableFromInline let ERR_MSG_ROTATE_RIGHT:    String = "\(ERR_MSG_PFX): Cannot rotate right - no left child node."

@usableFromInline protocol KeyedItem: Hashable, Comparable {
    associatedtype K where K: Comparable & Hashable

    var key: K { get }
}

@usableFromInline struct Tree<T: KeyedItem> {
    @usableFromInline var rootNode: TNode<T>? = nil

    @inlinable init() {}

    @inlinable subscript(key: T.K) -> T? {
        guard let r = rootNode, let n = r.find(key: key) else { return nil }
        return n.item
    }

    @inlinable mutating func insert(_ item: T) {
        if let r = rootNode { rootNode = r.insert(item: item) }
        else { rootNode = TNode<T>(item: item) }
    }

    @inlinable mutating func remove(key: T.K) {
        guard let r = rootNode, let n = r.find(key: key) else { return }
        rootNode = n.remove()
    }
}

@usableFromInline class TNode<T: KeyedItem>: Hashable {
    //@f:0
    @usableFromInline enum Color: UInt8 { case Black = 0, Red   = 1 }
    @usableFromInline enum Side:  Int   { case Left  = 0, Right = 1 }

    @usableFromInline private(set) var item: T
    //@f:1

    @usableFromInline convenience init(item: T) {
        self.init(item: item, color: .Black)
    }

    private init(item: T, color: Color) {
        self.item = item
        self.color = color
    }

    @usableFromInline func find(key k: T.K) -> TNode<T>? { foo(key: k, onHit: { $0 }, onMiss: { _, _ in nil }) }

    @usableFromInline func insert(item i: T) -> TNode<T> {
        foo(key: i.key) { n in
            n.item = i
            return n.root
        } onMiss: { p, sd in
            let n = TNode<T>(item: i, color: .Red)
            p[sd] = n
            return n.postInsert().root
        }!
    }

    @usableFromInline func remove() -> TNode<T>? {
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

    //@f:0
    @usableFromInline  var color: Color
    @usableFromInline  var nodes: [TNode<T>?] = [ nil, nil, nil ]
    //@f:1
}

extension TNode {
    //@f:0
    @inlinable var farLeft:    TNode<T>  { ifNil(self[.Left],  yes: { self }, no: { $0.farLeft  }) }
    @inlinable var farRight:   TNode<T>  { ifNil(self[.Right], yes: { self }, no: { $0.farRight }) }
    @inlinable var root:       TNode<T>  { ifNil(nodes[2],     yes: { self }, no: { $0.root     }) }
    //@f:1

    @inlinable subscript(sd: Side) -> TNode<T>? {
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

    @discardableResult @inlinable func paintRed() -> TNode<T> { color = .Red; return self }

    @discardableResult @inlinable func paintBlack() -> TNode<T> { color = .Black; return self }

    @discardableResult @inlinable func rotate(direction dir: Side) -> TNode<T> {
        guard let n = self[!dir] else { fatalError(dir == .Left ? ERR_MSG_ROTATE_LEFT : ERR_MSG_ROTATE_RIGHT) }
        swapWith(node: n)
        self[!dir] = n[dir]
        n[dir] = self
        swap(&color, &n.color)
        return self
    }

    @discardableResult @inlinable func makeOrphan() -> TNode<T> { swapWith(node: nil)! }

    @discardableResult @inlinable func swapWith(node n: TNode<T>?) -> TNode<T>? {
        ifNotNil(nodes[2]) { $0[side($0)] = n }
        return n
    }

    @inlinable func side(_ p: TNode<T>) -> Side { ((self === p.self[.Left]) ? .Left : .Right) }

    func foo(key k: T.K, onHit h: (TNode<T>) -> TNode<T>?, onMiss m: (TNode<T>, Side) -> TNode<T>?) -> TNode<T>? {
        func foo(side sd: Side, key k: T.K, onHit h: (TNode<T>) -> TNode<T>?, onMiss m: (TNode<T>, Side) -> TNode<T>?) -> TNode<T>? {
            guard let n = self[sd] else { return m(self, sd) }
            return n.foo(key: k, onHit: h, onMiss: m)
        }

        switch k <=> item.key {
            case .Equal:       return h(self)
            case .LessThan:    return foo(side: .Left, key: k, onHit: h, onMiss: m)
            case .GreaterThan: return foo(side: .Right, key: k, onHit: h, onMiss: m)
        }
    }

    func postInsert() -> TNode<T> {
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

    func preRemove(parent p: TNode<T>) {
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

    @inlinable static func == (lhs: TNode<T>, rhs: TNode<T>) -> Bool { lhs === rhs }
}

extension TNode.Color {
    @inlinable static func isBlack<T: KeyedItem>(_ node: TNode<T>?) -> Bool { ((node == nil) || (node!.color == .Black)) }

    @inlinable static func isRed<T: KeyedItem>(_ node: TNode<T>?) -> Bool { ((node != nil) && (node!.color == .Red)) }
}

extension TNode.Side {
    @inlinable static prefix func ! (side: Self) -> Self { (side == .Left ? .Right : .Left) }
}

infix operator <=>: ComparisonPrecedence

@usableFromInline enum ComparisonResults { case LessThan, Equal, GreaterThan }

@inlinable func <=> <T>(left: T?, right: T?) -> ComparisonResults where T: Comparable {
    ((left == right) ? .Equal : (((right != nil) && ((left == nil) || (left! < right!))) ? .LessThan : .GreaterThan))
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
