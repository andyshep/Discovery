//
//  Publisher+Extensions.swift
//  Discovery
//
//  Created by Andrew Shepard on 3/7/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Foundation
import Combine

// http://trycombine.com/posts/simple-custom-combine-operators/

extension Publisher {
    func `do`(onNext next: @escaping () -> ()) -> Publishers.HandleEvents<Self> {
        return handleEvents(receiveOutput: { _ in
            next()
        })
    }
    
    func `do`(onNext next: @escaping (Output) -> ()) -> Publishers.HandleEvents<Self> {
        return handleEvents(receiveOutput: { output in
            next(output)
        })
    }
}

extension Publisher {
    func flatMapLatest<T: Publisher>(_ transform: @escaping (Self.Output) -> T) -> Publishers.SwitchToLatest<T, Publishers.Map<Self, T>> where T.Failure == Self.Failure {
        map(transform).switchToLatest()
    }
}

extension Publisher {
    func subscribe(andStoreIn cancellables: inout [AnyCancellable]) {
        sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
    }
    
    func subscribe(andStoreIn cancellables: inout Set<AnyCancellable>) {
        sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
    }
}

extension Array where Element: AnyCancellable {
    mutating func cancel() {
        forEach { $0.cancel() }
        removeAll()
    }
}

extension Set where Element: AnyCancellable {
    mutating func cancel() {
        forEach { $0.cancel() }
        removeAll()
    }
}
