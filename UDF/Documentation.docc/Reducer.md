# Reducer

Pure functions that update state based on actions.

## Overview

A `Reducer` is a pure function that takes the current state and an action, then returns a new state. Reducers are the only place where state updates should occur in a UDF application. They are pure functions, meaning they should not have side effects and should always return the same output for the same input.

### Key Principles

- **Pure Functions**: No side effects, same input always produces same output
- **Immutable Updates**: Create new state, don't modify existing state
- **Predictable**: Easy to test and reason about
- **Composable**: Can be combined and split into smaller reducers

## Example

```swift
// Basic reducer
let counterReducer: Reducer<AppState> = { state, action in
    switch action {
    case is IncrementAction:
        state.counter += 1
        
    case is DecrementAction:
        state.counter -= 1
        
    case let action as SetCounterAction:
        state.counter = action.value
        
    default:
        break
    }
}

// More complex reducer
let userReducer: Reducer<AppState> = { state, action in
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
        
    case let action as UpdateUserProfileAction:
        state.user?.name = action.name
        state.user?.email = action.email
        
    default:
        break
    }
}
```

## Reducer Composition

You can combine multiple reducers into a single reducer:

```swift
// Individual reducers
let userReducer: Reducer<AppState> = { state, action in
    switch action {
    case let action as LoadUserAction:
        state.isLoading = true
    case let action as UserLoadedAction:
        state.user = action.user
        state.isLoading = false
    default:
        break
    }
}

let settingsReducer: Reducer<AppState> = { state, action in
    switch action {
    case let action as UpdateThemeAction:
        state.settings.theme = action.theme
    case let action as UpdateLanguageAction:
        state.settings.language = action.language
    default:
        break
    }
}

// Combined reducer
let appReducer: Reducer<AppState> = { state, action in
    userReducer(&state, action)
    settingsReducer(&state, action)
}
```

## Modular Reducers

For large applications, you can create modular reducers:

```swift
// User module reducer
struct UserState {
    var currentUser: User?
    var isLoading: Bool = false
    var error: String?
}

let userModuleReducer: Reducer<UserState> = { state, action in
    switch action {
    case let action as LoadUserAction:
        state.isLoading = true
        state.error = nil
        
    case let action as UserLoadedAction:
        state.currentUser = action.user
        state.isLoading = false
        
    case let action as UserLoadErrorAction:
        state.error = action.message
        state.isLoading = false
        
    default:
        break
    }
}

// Main app state
struct AppState {
    var user: UserState = UserState()
    var settings: SettingsState = SettingsState()
}

// Main reducer that delegates to module reducers
let appReducer: Reducer<AppState> = { state, action in
    userModuleReducer(&state.user, action)
    settingsModuleReducer(&state.settings, action)
}
```

## Reducer Best Practices

### Keep Reducers Pure
Reducers should not have side effects:

```swift
// Good - pure function
let counterReducer: Reducer<AppState> = { state, action in
    switch action {
    case is IncrementAction:
        state.counter += 1
    default:
        break
    }
}

// Avoid - side effects in reducer
let badReducer: Reducer<AppState> = { state, action in
    switch action {
    case is IncrementAction:
        state.counter += 1
        // Don't do this in a reducer
        Analytics.track("counter_incremented")
        UserDefaults.standard.set(state.counter, forKey: "counter")
    default:
        break
    }
}
```

### Handle All Actions
Always include a default case to handle unknown actions:

```swift
let userReducer: Reducer<AppState> = { state, action in
    switch action {
    case let action as LoadUserAction:
        state.isLoading = true
        
    case let action as UserLoadedAction:
        state.user = action.user
        state.isLoading = false
        
    default:
        // Handle unknown actions gracefully
        break
    }
}
```

### Use Type-Safe Action Handling
Leverage Swift's type system for safer action handling:

```swift
// Good - type-safe
let userReducer: Reducer<AppState> = { state, action in
    switch action {
    case let action as LoadUserAction:
        state.isLoading = true
        
    case let action as UserLoadedAction:
        state.user = action.user
        state.isLoading = false
        
    default:
        break
    }
}

// Alternative - using pattern matching
let userReducer: Reducer<AppState> = { state, action in
    if let loadAction = action as? LoadUserAction {
        state.isLoading = true
    } else if let loadedAction = action as? UserLoadedAction {
        state.user = loadedAction.user
        state.isLoading = false
    }
}
```

### Create Reusable Reducers
Extract common patterns into reusable reducers:

```swift
// Generic loading reducer
func createLoadingReducer<State>(
    isLoadingKeyPath: WritableKeyPath<State, Bool>,
    errorKeyPath: WritableKeyPath<State, String?>
) -> Reducer<State> {
    return { state, action in
        switch action {
        case is LoadUserAction:
            state[keyPath: isLoadingKeyPath] = true
            state[keyPath: errorKeyPath] = nil
            
        case is UserLoadedAction:
            state[keyPath: isLoadingKeyPath] = false
            
        case let action as UserLoadErrorAction:
            state[keyPath: errorKeyPath] = action.message
            state[keyPath: isLoadingKeyPath] = false
            
        default:
            break
        }
    }
}
```

## Testing Reducers

Reducers are pure functions, making them easy to test:

```swift
class ReducerTests: XCTestCase {
    func testCounterReducer() {
        var state = AppState(counter: 0)
        
        // Test increment
        counterReducer(&state, IncrementAction())
        XCTAssertEqual(state.counter, 1)
        
        // Test decrement
        counterReducer(&state, DecrementAction())
        XCTAssertEqual(state.counter, 0)
        
        // Test set value
        counterReducer(&state, SetCounterAction(value: 10))
        XCTAssertEqual(state.counter, 10)
    }
    
    func testUserReducer() {
        var state = AppState()
        
        // Test loading state
        userReducer(&state, LoadUserAction(userId: "123"))
        XCTAssertTrue(state.isLoading)
        XCTAssertNil(state.error)
        
        // Test loaded state
        let user = User(id: "123", name: "John")
        userReducer(&state, UserLoadedAction(user: user))
        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.user?.id, "123")
    }
}
```

## Summary

Reducers are the core of state management in UDF:

- **Pure Functions**: No side effects, predictable behavior
- **State Updates**: The only place where state should be modified
- **Composable**: Can be combined and split for modularity
- **Testable**: Easy to test due to pure function nature
- **Predictable**: Same input always produces same output

Design your reducers to be simple, focused, and easy to understand. Keep them pure and avoid side effects to maintain the benefits of the unidirectional data flow pattern.
