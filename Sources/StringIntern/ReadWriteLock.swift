/*===============================================================================================================================================================================*
 *     PROJECT: StringIntern
 *    FILENAME: ReadWriteLock.swift
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

#if os(Windows)
    import WinSDK

    fileprivate typealias OSRWLock = UnsafeMutablePointer<SRWLOCK>
    fileprivate typealias OSThreadKey = DWORD
#elseif CYGWIN
    fileprivate typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t?>
    fileprivate typealias OSThreadKey = pthread_key_t
#else
    fileprivate typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t>
    fileprivate typealias OSThreadKey = pthread_key_t
#endif

@usableFromInline class ReadWriteLock {
    private var lock: OSRWLock

    init() {
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
    @inlinable func readUnlock() {
        #if os(Windows)
            ReleaseSRWLockShared(lock)
        #else
            pthread_rwlock_unlock(lock)
        #endif
    }

    @inlinable func writeUnlock() {
        #if os(Windows)
            ReleaseSRWLockExclusive(lock)
        #else
            pthread_rwlock_unlock(lock)
        #endif
    }

    @inlinable func withReadLock<T>(_ body: () throws -> T) rethrows -> T {
        #if os(Windows)
            AcquireSRWLockShared(lock)
        #else
            guard pthread_rwlock_rdlock(lock) == 0 else { fatalError("Unknown Error.") }
        #endif
        defer { readUnlock() }
        return try body()
    }

    @inlinable func withWriteLock<T>(_ body: () throws -> T) rethrows -> T {
        #if os(Windows)
            AcquireSRWLockExclusive(lock)
        #else
            guard pthread_rwlock_wrlock(lock) == 0 else { fatalError("Unknown Error.") }
        #endif
        defer { writeUnlock() }
        return try body()
    }
}
