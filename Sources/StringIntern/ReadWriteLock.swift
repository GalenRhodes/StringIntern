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

class ReadWriteLock {
    private enum RWState { case None, Read, Write }

    @ThreadLocal private var rwState: RWState = .None
    private var              lock:    OSRWLock

    init() {
        lock = OSRWLock.allocate(capacity: 1)
        #if os(Windows)
            InitializeSRWLock(lock)
        #else
            guard pthread_rwlock_init(lock, nil) == 0 else { fatalError("Unable to initialize read/write lock.") }
        #endif
        rwState = .None
    }

    deinit {
        #if !os(Windows)
            pthread_rwlock_destroy(lock)
        #endif
        lock.deallocate()
    }

    func readLock() {
        guard rwState == .None else { fatalError("Thread already owns the lock  for \(rwState == .Read ? "reading" : "writing").") }
        #if os(Windows)
            AcquireSRWLockShared(lock)
        #else
            guard pthread_rwlock_rdlock(lock) == 0 else { fatalError("Unknown Error.") }
        #endif
        rwState = .Read
    }

    func tryReadLock() -> Bool {
        guard rwState == .None else { fatalError("Thread already owns the lock  for \(rwState == .Read ? "reading" : "writing").") }
        var success: Bool = false
        #if os(Windows)
            success = (TryAcquireSRWLockShared(lock) != 0)
        #else
            let r = pthread_rwlock_tryrdlock(lock)
            guard value(r, isOneOf: 0, EBUSY) else { fatalError("Unknown Error.") }
            success = (r == 0)
        #endif
        if success { rwState = .Read }
        return success
    }

    func writeLock() {
        guard rwState == .None else { fatalError("Thread already owns the lock  for \(rwState == .Read ? "reading" : "writing").") }
        #if os(Windows)
            AcquireSRWLockExclusive(lock)
        #else
            guard pthread_rwlock_wrlock(lock) == 0 else { fatalError("Unknown Error.") }
        #endif
        rwState = .Write
    }

    func tryWriteLock() -> Bool {
        guard rwState == .None else { fatalError("Thread already owns the lock  for \(rwState == .Read ? "reading" : "writing").") }
        var success: Bool = false
        #if os(Windows)
            success = (TryAcquireSRWLockExclusive(lock) != 0)
        #else
            let r = pthread_rwlock_tryrdlock(lock)
            guard value(r, isOneOf: 0, EBUSY) else { fatalError("Unknown Error.") }
            success = (r == 0)
        #endif
        if success { rwState = .Write }
        return success
    }

    func unlock() {
        switch rwState {
            case .Read:
                #if os(Windows)
                    ReleaseSRWLockShared(lock)
                #else
                    pthread_rwlock_unlock(lock)
                #endif
            case .Write:
                #if os(Windows)
                    ReleaseSRWLockExclusive(lock)
                #else
                    pthread_rwlock_unlock(lock)
                #endif
            default:
                fatalError("Thread does not currently own the lock.")
        }
        rwState = .None
    }
}

extension ReadWriteLock {

    @inlinable func withReadLock<T>(_ body: () throws -> T) rethrows -> T {
        readLock()
        defer { unlock() }
        return try body()
    }

    @inlinable func withWriteLock<T>(_ body: () throws -> T) rethrows -> T {
        writeLock()
        defer { unlock() }
        return try body()
    }

    @inlinable func tryWithReadLock<T>(_ body: () throws -> T) rethrows -> T? {
        guard tryReadLock() else { return nil }
        defer { unlock() }
        return try body()
    }

    @inlinable func tryWithWriteLock<T>(_ body: () throws -> T) rethrows -> T? {
        guard tryWriteLock() else { return nil }
        defer { unlock() }
        return try body()
    }
}

