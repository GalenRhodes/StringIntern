/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: TNode.swift
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

let ERR_MSG_PFX:             String = "Internal Inconsistency Error"
let ERR_MSG_MISSING_SIBLING: String = "\(ERR_MSG_PFX): Missing Sibling"
let ERR_MSG_MISSING_NEPHEW:  String = "\(ERR_MSG_PFX): Missing Distant Nephew"
let ERR_MSG_ROTATE_LEFT:     String = "\(ERR_MSG_PFX): Cannot rotate left - no right child node."
let ERR_MSG_ROTATE_RIGHT:    String = "\(ERR_MSG_PFX): Cannot rotate right - no left child node."

class TNode<K, T> where K: Comparable, T: KeyedItem<K> {

    typealias N = TNode<K, T>

    //@f:0
    var root:     N { Q(ifNil(parentNode) { self } no: { $0.root     }) }
    var farRight: N { Q(ifNil(rightNode)  { self } no: { $0.farRight }) }
    var farLeft:  N { Q(ifNil(leftNode)   { self } no: { $0.farLeft  }) }

    private(set) var item:       T
    private(set) var color:      Color
    private(set) var parentNode: N?
    private(set) var leftNode:   N?
    private(set) var rightNode:  N?
    //@f:1

    convenience init(item: T) {
        self.init(item: item, color: .Black)
    }

    private init(item: T, color: Color) {
        self.item = item
        self.color = color
    }

    func find(key k: K) -> N? {
        switch k <=> item.key {
            case .Equal:       return self
            case .LessThan:    if let n = leftNode { return n.find(key: k) }
            case .GreaterThan: if let n = rightNode { return n.find(key: k) }
        }
        return nil
    }

    func insert(key: K, item: T) -> N {
        switch key <=> item.key {
            case .Equal:
                self.item = item
                return root
            case .LessThan:
                if let l = leftNode { return l.insert(key: key, item: item) }
                let l = N(item: item, color: .Red)
                l.parentNode = self
                leftNode = l
                l.insert01()
                return l.root
            case .GreaterThan:
                if let r = rightNode { return r.insert(key: key, item: item) }
                let r = N(item: item, color: .Red)
                r.parentNode = self
                rightNode = r
                r.insert01()
                return r.root
        }
    }

    @discardableResult func makeOrphan() -> N {
        if let p = parentNode {
            ifThis((self === p.leftNode), thenDo: { p.leftNode = nil }, elseDo: { p.rightNode = nil })
            parentNode = nil
        }
        return self
    }

    func swapSelfWith(node n: N) {
        n.makeOrphan()
        if let p = parentNode {
            parentNode = nil
            n.parentNode = p
            ifThis((self === p.leftNode), thenDo: { p.leftNode = n }, elseDo: { p.rightNode = n })
        }
    }

    func rotateLeft() {
        guard let r = rightNode else { fatalError(ERR_MSG_ROTATE_LEFT) }
        let l = r.leftNode
        swapSelfWith(node: r)
        r.leftNode = self
        parentNode = r
        rightNode = l
        if let n = l { n.parentNode = self }
        swap(&color, &r.color)
    }

    func rotateRight() {
        guard let l = leftNode else { fatalError(ERR_MSG_ROTATE_RIGHT) }
        let r = l.rightNode
        swapSelfWith(node: l)
        l.rightNode = self
        parentNode = l
        leftNode = r
        if let n = r { n.parentNode = self }
        swap(&color, &l.color)
    }
}

extension TNode {
    @inlinable var sibling: N? { parentNode?[!side] }
    @inlinable var isLeft:  Bool { vOnSide(neither: false, left: true, right: false) }
    @inlinable var isRight: Bool { vOnSide(neither: false, left: false, right: true) }
    @inlinable var side:    Side { vOnSide(neither: .Neither, left: .Left, right: .Right) }

    @inlinable func vOnSide<T>(neither n: @autoclosure () -> T, left l: @autoclosure () -> T, right r: @autoclosure () -> T) -> T { onSide(neither: n, left: { _ in l() }, right: { _ in r() }) }

    @inlinable func onSide<R>(neither: () throws -> R, left: (N) throws -> R, right: (N) throws -> R) rethrows -> R {
        guard let p = parentNode else { return try neither() }
        return try ((self === p.leftNode) ? left(p) : right(p))
    }

    @inlinable subscript(sd: Side) -> N? {
        switch sd {
            case .Left:    return leftNode
            case .Right:   return rightNode
            case .Neither: return nil
        }
    }

    @inlinable func makeBlack() { color = .Black }

    @inlinable func makeRed() { color = .Red }

    @inlinable func rotate(direction dir: Side) {
        switch dir {
            case .Left:    rotateLeft()
            case .Right:   rotateRight()
            case .Neither: break
        }
    }
}

extension TNode {
    @inlinable func insert01() {
        ifNil(parentNode, yes: { makeBlack() }, no: { insert02(parent: $0) })
    }

    func insert02(parent p: N) {
        if Color.isRed(p) {
            if let g = p.parentNode {
                if let u = p.sibling, Color.isRed(u) {
                    // This node has a red parent and a red uncle which means the grandparent is black.
                    // Recolor nodes and start over at the grandparent.
                    p.makeBlack()
                    u.makeBlack()
                    g.makeRed()
                    g.insert01()
                }
                else {
                    insert05(parent: p, grandparent: g)
                }
            }
            else {
                // This node's parent is the root so it gets painted black.
                p.makeBlack()
            }
        }
    }

    func insert05(parent p: N, grandparent g: N) {
        if p.isLeft {
            if isRight { p.rotateLeft() }
            g.rotateRight()
        }
        else {
            if isLeft { p.rotateRight() }
            g.rotateLeft()
        }
    }
}

extension TNode {
    @inlinable var isAllBlack: Bool { Color.isBlack(self) && Color.isBlack(leftNode) && Color.isBlack(rightNode) }

    func remove() -> N? {
        if let l = leftNode, let r = rightNode {
            // Two children. Find the next node in order and swap with it then delete.
            let other = (Bool.random() ? l.farRight : r.farLeft)
            item = other.item
            return other.remove()
        }
        else if let c = (leftNode ?? rightNode) {
            // This node is black and has one red child.
            c.makeBlack()
            swapSelfWith(node: c)
            return c.root
        }
        else if let p = parentNode {
            // No Children
            if Color.isBlack(self) { remove01(parent: p) }
            makeOrphan()
            return p.root
        }
        // This is the only node so it can just go away
        // and leave an empty tree.
        return nil
    }

    func remove01(parent p: N) {
        ifNil(sibling, yes: { fatalError(ERR_MSG_MISSING_SIBLING) }, no: { remove02(parent: p, sibling: $0) })
    }

    @inlinable func remove02(parent p: N, sibling s: N) {
        ifThis(Color.isRed(s), thenDo: { remove03(parent: p) }, elseDo: { remove04(side: side, parent: p, sibling: s) })
    }

    func remove03(parent p: N) {
        p.rotate(direction: side)
        ifNil(sibling, yes: { fatalError(ERR_MSG_MISSING_SIBLING) }, no: { remove04(side: side, parent: p, sibling: $0) })
    }

    @inlinable func remove04(side sd: Side, parent p: N, sibling s: N) {
        ifThis(s.isAllBlack, thenDo: { remove05(parent: p, sibling: s) }, elseDo: { remove06(side: sd, parent: p, sibling: s, closeNephew: s[sd] as N?) })
    }

    @inlinable func remove05(parent p: N, sibling s: N) {
        s.makeRed()
        ifThis(Color.isBlack(p), thenDo: { ifNotNil(p.parentNode, { p.remove01(parent: $0) }) }, elseDo: { p.makeBlack() })
    }

    @inlinable func remove06(side sd: Side, parent p: N, sibling s: N, closeNephew c: N?) {
        Color.isRed(c) ? remove07(side: sd, parent: p, sibling: s) : remove08(side: sd, parent: p, sibling: s)
    }

    @inlinable func remove07(side sd: Side, parent p: N, sibling s: N) {
        s.rotate(direction: !sd)
        ifNil(sibling, yes: { fatalError(ERR_MSG_MISSING_SIBLING) }, no: { remove08(side: sd, parent: p, sibling: $0) })
    }

    @inlinable func remove08(side sd: Side, parent p: N, sibling s: N) {
        ifNil(s[!sd] as N?, yes: { fatalError(ERR_MSG_MISSING_NEPHEW) }, no: {
            $0.makeBlack()
            p.rotate(direction: sd)
        })
    }
}
