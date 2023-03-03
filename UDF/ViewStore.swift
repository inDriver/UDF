//  Copyright 2021  Suol Innovations Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Combine
import UIKit
/**
 If you need to use UDF in SwiftUI
 1. Create SwiftUI View with:

 struct CounterView: View {

     @ObservedObject
     var store: ViewStore<Counter.State, Counter.ViewActions>

     var body: some View {
         HStack {
             Button("-") {
                 store.dispatch(.minusDidTap)
             }
             Text("\(store.state.count)")
             Button("+") {
                 store.dispatch(.plusDidTap)
             }
         }
         .frame(alignment: .center)
     }
 }

 2. Create ViewStore from Store and pass it to the View:

        let view = CounterView(store: store.viewStore(\.counterState))
        return UIHostingController(rootView: view)
*/
@_spi(Private) public class ViewStore<State, ActionType: Action>: ObservableObject, Dispatcher {

    @Published
    var store: Store<State>
    var cancelables = Set<AnyCancellable>()

    public var state: State {
        store.state
    }

    public init(store: Store<State>) {
        self.store = store

        store.publisher.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancelables)
    }

    public func dispatch(_ action: ActionType) {
        store.dispatch(action)
    }
}

@_spi(Private) public extension Store {
    func viewStore<ScopeState, ActionType: Action>(
        _ keypath: KeyPath<State, ScopeState>
    ) -> ViewStore<ScopeState, ActionType> {
        .init(store: scope(keypath))
    }
}

@_spi(Private) public protocol Dispatcher<ActionType> {

    associatedtype ActionType: Action

    func dispatch(_ action: ActionType)
}
