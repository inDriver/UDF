# Store

The central state container that manages your application's state and dispatches actions.

## Overview

The `Store` is the heart of the UDF framework. It holds your application's state and provides the only way to update that state through actions. The store follows the unidirectional data flow pattern, ensuring that all state changes are predictable and traceable.

### Key Responsibilities

- **State Management**: Holds the current state of your application
- **Action Dispatching**: Processes actions and updates state through reducers
- **State Observation**: Notifies subscribers when state changes
- **Action Observation**: Notifies subscribers when actions are dispatched
- **Scope Management**: Provides scoped stores for modular architecture

## Example

```swift
// Define your application state
struct AppState {
    var user: User?
    var isLoading: Bool = false
    var error: String?
}

// Create a reducer
let appReducer: Reducer<AppState> = { state, action in
    switch action {
    case let action as LoadUserAction:
        state.isLoading = true
        state.error = nil
        
    case let action as UserLoadedAction:
        state.user = action.user
        state.isLoading = false
        
    case let action as UserLoadErrorAction:
        state.error = action.message
        state.isLoading = false
        
    default:
        break
    }
}

// Create the store
let store = Store(
    state: AppState(),
    reducer: appReducer
)

// Observe state changes
store.observe { state in
    print("State updated: \(state)")
}.dispose(on: disposer)

// Dispatch actions
store.dispatch(LoadUserAction(userId: "123"))
```

## State Observation

The store provides methods to observe state changes:

```swift
// Observe on main queue
store.observe(on: .main) { state in
    // Update UI with new state
}.dispose(on: disposer)

// Observe on background queue
store.observe(on: .global()) { state in
    // Process state on background
}.dispose(on: disposer)
```

## Action Observation

You can also observe when actions are dispatched:

```swift
store.onAction { state, action in
    print("Action dispatched: \(action)")
    print("New state: \(state)")
}.dispose(on: disposer)
```

## Scoped Stores

For modular architecture, you can create scoped stores:

```swift
// Create a scoped store for user-related state
let userStore = store.scope(
    \.user,
    shouldUpdateLocalState: { oldUser, newUser in
        oldUser?.id != newUser?.id
    }
)

// Use the scoped store
userStore.observe { user in
    // Only notified when user changes
}.dispose(on: disposer)
```

## Dynamic Reducers

You can add and remove reducers dynamically:

```swift
// Add a dynamic reducer
store.add(reducer: userReducer, withKey: "user")

// Add a reducer for a specific state path
store.add(
    reducer: userReducer,
    state: \.user,
    withKey: "user"
)

// Remove a reducer
store.remove(reducerWithKey: "user")
```

## Thread Safety

The store is thread-safe and uses a dedicated dispatch queue for all operations. All state updates and notifications happen on this queue to ensure consistency.

## Summary

The `Store` is the central component of the UDF framework that:

- Manages application state
- Dispatches actions to update state
- Notifies subscribers of state and action changes
- Provides scoped stores for modular architecture
- Ensures thread-safe operations

Use the store as the single source of truth for your application's state, and always update state through actions and reducers.

