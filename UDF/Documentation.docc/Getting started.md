# Getting started

Learn how to set up and use the UDF framework in your iOS application.

## Overview

UDF (Unidirectional Data Flow) is a Swift framework that implements the unidirectional data flow architecture pattern. This pattern ensures that data flows in only one direction through your application, making state management predictable and testable.

The framework consists of several core components:
- **Store**: The central state container
- **Action**: Events that describe what happened
- **Reducer**: Pure functions that update state based on actions
- **Component**: UI or service components that connect to the store
- **Connector**: Objects that transform state into props for components

### Key Benefits

- **Predictable State Management**: All state changes flow through a single path
- **Testability**: Pure functions and isolated components make testing easier
- **Debugging**: Clear data flow makes it easier to track down issues
- **Scalability**: Modular architecture supports large applications

## Example

Here's a simple example of how to set up a UDF application:

```swift
// 1. Define your state
struct AppState {
    var counter: Int = 0
}

// 2. Define actions
struct IncrementAction: Action {}
struct DecrementAction: Action {}

// 3. Create a reducer
let appReducer: Reducer<AppState> = { state, action in
    switch action {
    case is IncrementAction:
        state.counter += 1
    case is DecrementAction:
        state.counter -= 1
    default:
        break
    }
}

// 4. Create the store
let store = Store(
    state: AppState(),
    reducer: appReducer
)

// 5. Create a component
class CounterViewController: UIViewController, ViewComponent {
    let disposer = Disposer()
    var props: CounterProps = CounterProps(count: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Connect to store
        connect(to: store) { state in
            CounterProps(count: state.counter)
        }
    }
    
    func updateProps() {
        // Update UI with props.count
    }
}

struct CounterProps: Equatable {
    let count: Int
}
```

## Summary

The UDF framework provides a robust foundation for building iOS applications with predictable state management. By following the unidirectional data flow pattern, you can create maintainable, testable, and scalable applications.

The main concepts to understand are:
- **Store**: Holds your application state and dispatches actions
- **Action**: Describes what happened in your app
- **Reducer**: Pure functions that update state based on actions
- **Component**: UI or service components that react to state changes
- **Connector**: Transforms state into props for components

Start with a simple example and gradually add complexity as you become more familiar with the patterns.
