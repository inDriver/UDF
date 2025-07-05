# Action

Events that describe what happened in your application and trigger state updates.

## Overview

`Action` is a marker protocol that represents events or intentions in your application. Actions are the only way to update the state in a UDF application. They describe what happened (not how to update the state), making your application's behavior predictable and testable.

### Key Principles

- **Descriptive**: Actions describe what happened, not how to handle it
- **Immutable**: Actions should be immutable data structures
- **Serializable**: Actions should be easily serializable for debugging
- **Type-Safe**: Use specific action types for different events

## Example

```swift
// Simple actions
struct IncrementCounterAction: Action {}
struct DecrementCounterAction: Action {}

// Actions with data
struct LoadUserAction: Action {
    let userId: String
}

struct UserLoadedAction: Action {
    let user: User
}

struct UserLoadErrorAction: Action {
    let message: String
}

// Complex actions
struct UpdateUserProfileAction: Action {
    let userId: String
    let name: String
    let email: String
    let avatar: URL?
}
```

## Action Categories

### User Actions
Actions triggered by user interactions:

```swift
struct ButtonTappedAction: Action {
    let buttonId: String
}

struct TextFieldChangedAction: Action {
    let fieldId: String
    let text: String
}

struct SwipeGestureAction: Action {
    let direction: SwipeDirection
}
```

### System Actions
Actions triggered by system events:

```swift
struct AppDidBecomeActiveAction: Action {}
struct AppWillResignActiveAction: Action {}
struct NetworkStatusChangedAction: Action {
    let isConnected: Bool
}
```

### Async Actions
Actions that represent asynchronous operations:

```swift
struct APIRequestStartedAction: Action {
    let requestId: String
    let endpoint: String
}

struct APIRequestCompletedAction: Action {
    let requestId: String
    let data: Data
}

struct APIRequestFailedAction: Action {
    let requestId: String
    let error: Error
}
```

## Dispatching Actions

Actions are dispatched through the store:

```swift
// Dispatch simple actions
store.dispatch(IncrementCounterAction())
store.dispatch(DecrementCounterAction())

// Dispatch actions with data
store.dispatch(LoadUserAction(userId: "123"))

// Dispatch from components
class UserViewController: UIViewController, ViewComponent {
    let disposer = Disposer()
    var props: UserProps = UserProps()
    
    @IBAction func loadUserButtonTapped() {
        // Dispatch action through the store
        store.dispatch(LoadUserAction(userId: "123"))
    }
}
```

## Action Handling in Reducers

Actions are handled in reducers to update state:

```swift
let userReducer: Reducer<AppState> = { state, action in
    switch action {
    case let action as LoadUserAction:
        state.isLoading = true
        state.error = nil
        // Trigger async operation here
        
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
```

## Action Observation

You can observe actions for logging, analytics, or side effects:

```swift
store.onAction { state, action in
    // Log all actions
    print("Action: \(type(of: action))")
    
    // Track analytics
    Analytics.track(action: action)
    
    // Handle side effects
    switch action {
    case is AppDidBecomeActiveAction:
        // Refresh data when app becomes active
        store.dispatch(RefreshDataAction())
    default:
        break
    }
}.dispose(on: disposer)
```

## Best Practices

### Action Naming
- Use descriptive names that explain what happened
- Use past tense for completed actions
- Use present tense for ongoing actions

```swift
// Good
struct UserProfileUpdatedAction: Action {}
struct DataLoadingStartedAction: Action {}

// Avoid
struct UpdateUserAction: Action {}
struct LoadDataAction: Action {}
```

### Action Structure
- Keep actions simple and focused
- Include only necessary data
- Make actions immutable

```swift
// Good - focused and immutable
struct UserNameChangedAction: Action {
    let newName: String
}

// Avoid - too complex
struct UserAction: Action {
    var name: String
    var email: String
    var avatar: URL?
    var isEditing: Bool
}
```

### Action Organization
- Group related actions together
- Use namespaces for large applications
- Consider using enums for related actions

```swift
// Using enums for related actions
enum UserAction {
    case load(userId: String)
    case loaded(user: User)
    case loadFailed(error: String)
    case update(profile: UserProfile)
    case updateCompleted(user: User)
    case updateFailed(error: String)
}
```

## Summary

Actions are the foundation of the unidirectional data flow pattern:

- **Describe events**: Actions describe what happened in your app
- **Trigger updates**: Actions are the only way to update state
- **Enable testing**: Actions make behavior predictable and testable
- **Support debugging**: Actions provide a clear audit trail

Design your actions to be descriptive, immutable, and focused on specific events in your application.
