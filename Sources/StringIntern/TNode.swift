/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: TNode.swift
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

let ERR_MSG_PFX:             String = "Internal Inconsistency Error"
let ERR_MSG_MISSING_GRAND:   String = "\(ERR_MSG_PFX): Missing Grandparent"
let ERR_MSG_MISSING_SIBLING: String = "\(ERR_MSG_PFX): Missing Sibling"
let ERR_MSG_MISSING_NEPHEW:  String = "\(ERR_MSG_PFX): Missing Distant Nephew"
let ERR_MSG_ROTATE_LEFT:     String = "\(ERR_MSG_PFX): Cannot rotate left - no right child node."
let ERR_MSG_ROTATE_RIGHT:    String = "\(ERR_MSG_PFX): Cannot rotate right - no left child node."

class TNode<T: KeyedItem>: Hashable {
    //@f:0
    enum Color: UInt8 { case Black = 0, Red   = 1 }
    enum Side:  Int   { case Left  = 0, Right = 1 }

    private(set) var item: T
    //@f:1

    convenience init(item: T) {
        self.init(item: item, color: .Black)
    }

    private init(item: T, color: Color) {
        self.item = item
        self.color = color
    }

    func find(key k: T.K) -> TNode<T>? {
        switch k <=> item.key {
            case .Equal:       return self
            case .LessThan:    return _find(key: k, side: .Left)
            case .GreaterThan: return _find(key: k, side: .Right)
        }
    }

    private func _find(key k: T.K, side sd: Side) -> TNode<T>? {
        guard let n = self[sd] else { return nil }
        return n.find(key: k)
    }

    func insert(item i: T) -> TNode<T> {
        switch i.key <=> item.key {
            case .Equal:
                self.item = i
                return root
            case .LessThan:
                return _insert(item: i, side: .Left)
            case .GreaterThan:
                return _insert(item: i, side: .Right)
        }
    }

    func remove() -> TNode<T>? {
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
        else if let p = parentNode {
            let r = p.root
            if Color.isBlack(self) { preRemove(parent: p) }
            makeOrphan()
            return r
        }
        return nil
    }

    //@f:0
    private var color:      Color
    private var parentNode: TNode<T>?
    private var children:   [TNode<T>?] = [ nil, nil ]
    //@f:1
}

extension TNode {
    //@f:0
    private var farLeft:    TNode<T>  { self[.Left] == nil   ? self : self[.Left]!.farLeft   }
    private var farRight:   TNode<T>  { self[.Right] == nil  ? self : self[.Right]!.farRight }
    private var root:       TNode<T>  { parentNode == nil ? self : parentNode!.root    }
    private var isAllBlack: Bool      { Color.isBlack(self) && Color.isBlack(self[.Left]) && Color.isBlack(self[.Right]) }
    //@f:1

    private subscript(sd: Side) -> TNode<T>? {
        get { children[sd.rawValue] }
        set {
            let c = self[sd]
            if c != newValue {
                if let n = c { n.parentNode = nil }
                if let n = newValue { n.makeOrphan().parentNode = self }
                children[sd.rawValue] = newValue
            }
        }
    }

    private func paintRed() { color = .Red }

    private func paintBlack() { color = .Black }

    private func rotate(direction dir: Side) {
        guard let n = self[!dir] else { fatalError(dir == .Left ? ERR_MSG_ROTATE_LEFT : ERR_MSG_ROTATE_RIGHT) }
        swapWith(node: n)
        self[!dir] = n[dir]
        n[dir] = self
        swap(&color, &n.color)
    }

    @discardableResult private func makeOrphan() -> TNode<T> { swapWith(node: nil)! }

    @discardableResult private func swapWith(node n: TNode<T>?) -> TNode<T>? {
        ifNotNil(parentNode, { p in p[side(p)] = n })
        return n
    }

    private func side(_ p: TNode<T>) -> Side { ((self === p.self[.Left]) ? .Left : .Right) }

    private func _insert(item i: T, side sd: Side) -> TNode<T> {
        if let n = self[sd] { return n.insert(item: i) }
        let n = TNode<T>(item: i, color: .Red)
        n.parentNode = self
        self[sd] = n
        n.postInsert()
        return n.root
    }

    private func postInsert() {
        guard let p = parentNode else { return paintBlack() }
        guard Color.isRed(p) else { return }
        guard let g = p.parentNode else { fatalError(ERR_MSG_MISSING_GRAND) }

        let ps = p.side(g)

        if let u = g[!ps], Color.isRed(u) {
            p.paintBlack()
            u.paintBlack()
            g.paintRed()
            g.postInsert()
        }
        else {
            if side(p) != ps { p.rotate(direction: ps) }
            g.rotate(direction: !ps)
        }
    }

    private func preRemove(parent p: TNode<T>) {
        let sd = side(p)
        let xd = !sd
        var s  = mustHave(p[xd], ERR_MSG_MISSING_SIBLING)

        if Color.isRed(s) {
            p.rotate(direction: sd)
            s = mustHave(p[xd], ERR_MSG_MISSING_SIBLING)
        }

        if s.isAllBlack {
            s.paintRed()
            if Color.isRed(p) { p.paintBlack() }
            else if let g = p.parentNode { p.preRemove(parent: g) }
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

    func hash(into hasher: inout Hasher) { hasher.combine(item) }

    static func == (lhs: TNode<T>, rhs: TNode<T>) -> Bool { lhs === rhs }
}

extension TNode.Color {
    @inlinable static func isBlack<T: KeyedItem>(_ node: TNode<T>?) -> Bool { ((node == nil) || (node!.color == .Black)) }

    @inlinable static func isRed<T: KeyedItem>(_ node: TNode<T>?) -> Bool { ((node != nil) && (node!.color == .Red)) }
}

extension TNode.Side {
    @inlinable static prefix func ! (side: Self) -> Self { (side == .Left ? .Right : .Left) }
}
