//  Created by rturov on 15.02.2021.

public final class ActionDispatcherMock: ActionDispatcher {
    public private(set) var dispatchedActions = [Action]()

    public init() { }

    public func dispatch(_ action: Action) {
        dispatchedActions.append(action)
    }
}
