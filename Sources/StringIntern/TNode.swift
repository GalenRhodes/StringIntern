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
    func hash(into hasher: inout Hasher) { hasher.combine(item) }

    static func == (lhs: TNode<T>, rhs: TNode<T>) -> Bool { lhs === rhs }

    enum Color: UInt8 {
        case Black = 0
        case Red
    }

    enum Side {
        case Left
        case Right
        case Neither
    }

    //@f:0
    private(set) var item:       T
    private      var color:      Color
    private      var parentNode: TNode<T>?
    private      var _leftNode:   TNode<T>?
    private      var _rightNode:  TNode<T>?

    private      var root:       TNode<T>  { parentNode == nil ? self : parentNode!.root    }
    private      var farLeft:    TNode<T>  { leftNode == nil   ? self : leftNode!.farLeft   }
    private      var farRight:   TNode<T>  { rightNode == nil  ? self : rightNode!.farRight }
    private      var isAllBlack: Bool      { Color.isBlack(self) && Color.isBlack(leftNode) && Color.isBlack(rightNode) }
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
            case .LessThan:    if let n = leftNode { return n.find(key: k) }
            case .GreaterThan: if let n = rightNode { return n.find(key: k) }
        }
        return nil
    }

    func insert(item i: T) -> TNode<T> {
        switch i.key <=> item.key {
            case .Equal:
                self.item = i
                return root
            case .LessThan:
                if let l = leftNode { return l.insert(item: i) }
                let l = TNode<T>(item: i, color: .Red)
                l.parentNode = self
                leftNode = l
                l.postInsert()
                return l.root
            case .GreaterThan:
                if let r = rightNode { return r.insert(item: i) }
                let r = TNode<T>(item: i, color: .Red)
                r.parentNode = self
                rightNode = r
                r.postInsert()
                return r.root
        }
    }

    func remove() -> TNode<T>? {
        if let l = leftNode, let r = rightNode {
            let other = (Bool.random() ? l.farRight : r.farLeft)
            swap(&item, &other.item)
            return other.remove()
        }
        else if let c = (leftNode ?? rightNode) {
            c.paintBlack()
            swapSelfWith(node: c)
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

    private func preRemove(parent p: TNode<T>) {
        let sd = (self === p.leftNode ? Side.Left : Side.Right)
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

    private subscript(sd: Side) -> TNode<T>? {
        switch sd {
            case .Left:    return leftNode
            case .Right:   return rightNode
            case .Neither: return nil
        }
    }

    private func paintBlack() { color = .Black }

    private func paintRed() { color = .Red }

    private func rotate(direction dir: Side) {
        switch dir {
            case .Left:
                guard let r = rightNode else { fatalError(ERR_MSG_ROTATE_LEFT) }
                let l = r.leftNode
                swapSelfWith(node: r)
                r.leftNode = self
                parentNode = r
                rightNode = l
                if let n = l { n.parentNode = self }
                swap(&color, &r.color)
            case .Right:
                guard let l = leftNode else { fatalError(ERR_MSG_ROTATE_RIGHT) }
                let r = l.rightNode
                swapSelfWith(node: l)
                l.rightNode = self
                parentNode = l
                leftNode = r
                if let n = r { n.parentNode = self }
                swap(&color, &l.color)
            case .Neither:
                break
        }
    }

    @discardableResult private func makeOrphan() -> TNode<T> {
        guard let p = parentNode else { return self }
        if self === p._leftNode { p.leftNode = nil }
        else { p.rightNode = nil }
        return self
    }

    private func swapSelfWith(node n: TNode<T>) {
        n.makeOrphan()
        if let p = parentNode {
            parentNode = nil
            n.parentNode = p
            ifThis((self === p.leftNode), thenDo: { p.leftNode = n }, elseDo: { p.rightNode = n })
        }
    }

    private func postInsert() {
        guard let p = parentNode else { return paintBlack() }
        guard Color.isRed(p) else { return }
        guard let g = p.parentNode else { fatalError(ERR_MSG_MISSING_GRAND) }

        let ps = (p === g.leftNode ? Side.Left : Side.Right)

        if let u = g[!ps], Color.isRed(u) {
            p.paintBlack()
            u.paintBlack()
            g.paintRed()
            g.postInsert()
        }
        else {
            if (self === p.leftNode ? Side.Left : Side.Right) != ps { p.rotate(direction: ps) }
            g.rotate(direction: !ps)
        }
    }

    private var leftNode:  TNode<T>? {
        get { _leftNode }
        set {
            if _leftNode != newValue {
                _leftNode?.parentNode = nil
                newValue?.makeOrphan().parentNode = self
                _leftNode = newValue
            }
        }
    }
    private var rightNode: TNode<T>? {
        get { _rightNode }
        set {
            if _rightNode != newValue {
                _rightNode?.parentNode = nil
                newValue?.makeOrphan().parentNode = self
                _rightNode = newValue
            }
        }
    }
}

extension TNode.Color {
    @inlinable static func isBlack<T: KeyedItem>(_ node: TNode<T>?) -> Bool { ((node == nil) || (node!.color == .Black)) }

    @inlinable static func isRed<T: KeyedItem>(_ node: TNode<T>?) -> Bool { ((node != nil) && (node!.color == .Red)) }
}

extension TNode.Side {
    @inlinable static prefix func ! (side: Self) -> Self { (side == .Left ? .Right : (side == .Right ? .Left : .Neither)) }
}
