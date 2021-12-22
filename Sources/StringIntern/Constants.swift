/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: Constants.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/22/21
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

@usableFromInline let ERR_MSG_TREE_PFX: String = "Internal Inconsistency Error"
@usableFromInline let ERR_MSG_LOCK_PFX: String = "RWLock Error"

@usableFromInline let ERR_MSG_MISSING_GRAND:   String = "\(ERR_MSG_TREE_PFX): Missing Grandparent"
@usableFromInline let ERR_MSG_MISSING_SIBLING: String = "\(ERR_MSG_TREE_PFX): Missing Sibling"
@usableFromInline let ERR_MSG_MISSING_NEPHEW:  String = "\(ERR_MSG_TREE_PFX): Missing Distant Nephew"
@usableFromInline let ERR_MSG_ROTATE_LEFT:     String = "\(ERR_MSG_TREE_PFX): Cannot rotate left - no right child node."
@usableFromInline let ERR_MSG_ROTATE_RIGHT:    String = "\(ERR_MSG_TREE_PFX): Cannot rotate right - no left child node."

@usableFromInline let ERR_MSG_LOCK_FAILED:      String = "\(ERR_MSG_LOCK_PFX): Unable to acquire lock."
@usableFromInline let ERR_MSG_LOCK_INIT_FAILED: String = "\(ERR_MSG_LOCK_PFX): Unable to initialize read/write lock."
