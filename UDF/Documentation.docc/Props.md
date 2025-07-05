# Props

Immutable data structures that represent the view state for components.

## Overview

`Props` are immutable data structures that represent the state of a component's view. They are derived from the application state and contain only the data needed to render the component. Props follow the principle of immutability and should be `Equatable` to enable efficient updates.

### Key Principles

- **Immutable**: Props should be immutable data structures
- **Equatable**: Props must conform to `Equatable` for efficient updates
- **Focused**: Only include data needed for rendering
- **Derived**: Props are derived from application state, not stored directly

## Example

```swift
// Simple props
struct CounterProps: Equatable {
    let count: Int
    let isLoading: Bool
}

// Complex props
struct UserProfileProps: Equatable {
    let user: User?
    let isLoading: Bool
    let error: String?
    let canEdit: Bool
    let avatarURL: URL?
}

// Props with computed properties
struct ProductListProps: Equatable {
    let products: [Product]
    let isLoading: Bool
    let error: String?
    
    var isEmpty: Bool {
        return products.isEmpty && !isLoading
    }
    
    var hasError: Bool {
        return error != nil
    }
}
```

## Props Design Patterns

### Simple Props
For basic components, keep props simple and focused:

```swift
struct ButtonProps: Equatable {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
}

struct TextFieldProps: Equatable {
    let text: String
    let placeholder: String
    let isEditing: Bool
    let error: String?
}
```

### Composite Props
For complex views, compose props from multiple sources:

```swift
struct UserDetailProps: Equatable {
    // User data
    let user: User?
    let isLoading: Bool
    let error: String?
    
    // UI state
    let isEditing: Bool
    let canEdit: Bool
    
    // Navigation
    let canGoBack: Bool
    let canGoForward: Bool
}
```

### Computed Props
Use computed properties to derive additional information:

```swift
struct ShoppingCartProps: Equatable {
    let items: [CartItem]
    let isLoading: Bool
    
    var totalItems: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }
    
    var totalPrice: Decimal {
        return items.reduce(0) { $0 + $1.price * Decimal($1.quantity) }
    }
    
    var isEmpty: Bool {
        return items.isEmpty && !isLoading
    }
}
```

## Props Transformation

Props are created by transforming application state using connectors:

```swift
// Using a connector
struct UserProfileConnector: Connector {
    typealias State = AppState
    typealias Props = UserProfileProps
    
    func stateToProps(state: State, dispatcher: ActionDispatcher) -> Props {
        return UserProfileProps(
            user: state.user,
            isLoading: state.isLoading,
            error: state.error,
            canEdit: state.user != nil,
            avatarURL: state.user?.avatarURL
        )
    }
}

// Using a closure
let userProfileConnector = ClosureConnector<AppState, UserProfileProps> { state, dispatcher in
    return UserProfileProps(
        user: state.user,
        isLoading: state.isLoading,
        error: state.error,
        canEdit: state.user != nil,
        avatarURL: state.user?.avatarURL
    )
}
```

## Props in Components

Components receive props and update their UI accordingly:

```swift
class UserProfileViewController: UIViewController, ViewComponent {
    let disposer = Disposer()
    var props: UserProfileProps = UserProfileProps(
        user: nil,
        isLoading: false,
        error: nil,
        canEdit: false,
        avatarURL: nil
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Connect to store
        connect(to: store, by: UserProfileConnector())
    }
    
    func updateProps() {
        // Update UI based on props
        if props.isLoading {
            showLoadingIndicator()
        } else if let error = props.error {
            showError(error)
        } else if let user = props.user {
            showUserProfile(user)
        }
        
        editButton.isEnabled = props.canEdit
    }
}
```

## Props Best Practices

### Keep Props Immutable
Props should be immutable to prevent accidental modifications:

```swift
// Good - immutable
struct UserProps: Equatable {
    let name: String
    let email: String
    let avatarURL: URL?
}

// Avoid - mutable
struct BadUserProps: Equatable {
    var name: String
    var email: String
    var avatarURL: URL?
}
```

### Make Props Equatable
Props must conform to `Equatable` for efficient updates:

```swift
// Good - explicit Equatable conformance
struct CounterProps: Equatable {
    let count: Int
    let isLoading: Bool
    
    static func == (lhs: CounterProps, rhs: CounterProps) -> Bool {
        return lhs.count == rhs.count && lhs.isLoading == rhs.isLoading
    }
}

// Good - automatic Equatable (when all properties are Equatable)
struct SimpleProps: Equatable {
    let title: String
    let count: Int
    let isEnabled: Bool
}
```

### Include Only Necessary Data
Props should only contain data needed for rendering:

```swift
// Good - focused on UI needs
struct ProductCardProps: Equatable {
    let title: String
    let price: Decimal
    let imageURL: URL?
    let isInStock: Bool
}

// Avoid - including unnecessary data
struct BadProductCardProps: Equatable {
    let product: Product // Too much data
    let allCategories: [Category] // Not needed for this view
    let userPreferences: UserPreferences // Not relevant
}
```

### Use Optional Types Appropriately
Use optionals to represent nullable states:

```swift
struct UserProfileProps: Equatable {
    let user: User? // Optional - user might not be loaded
    let isLoading: Bool
    let error: String? // Optional - error might not exist
    let avatarURL: URL? // Optional - user might not have avatar
}
```

### Create Reusable Props
Extract common patterns into reusable props:

```swift
// Reusable loading state
struct LoadingStateProps: Equatable {
    let isLoading: Bool
    let error: String?
    
    var hasError: Bool {
        return error != nil
    }
}

// Use in other props
struct UserListProps: Equatable {
    let users: [User]
    let loadingState: LoadingStateProps
    let canLoadMore: Bool
}
```

## Props Testing

Props are easy to test since they are simple data structures:

```swift
class PropsTests: XCTestCase {
    func testUserProfileProps() {
        let user = User(id: "123", name: "John", email: "john@example.com")
        let props = UserProfileProps(
            user: user,
            isLoading: false,
            error: nil,
            canEdit: true,
            avatarURL: URL(string: "https://example.com/avatar.jpg")
        )
        
        XCTAssertEqual(props.user?.id, "123")
        XCTAssertFalse(props.isLoading)
        XCTAssertNil(props.error)
        XCTAssertTrue(props.canEdit)
        XCTAssertNotNil(props.avatarURL)
    }
    
    func testPropsEquality() {
        let props1 = CounterProps(count: 5, isLoading: false)
        let props2 = CounterProps(count: 5, isLoading: false)
        let props3 = CounterProps(count: 10, isLoading: false)
        
        XCTAssertEqual(props1, props2)
        XCTAssertNotEqual(props1, props3)
    }
}
```

## Summary

Props are the bridge between application state and component views:

- **Immutable**: Props should be immutable data structures
- **Equatable**: Must conform to `Equatable` for efficient updates
- **Focused**: Only include data needed for rendering
- **Derived**: Created by transforming application state
- **Testable**: Simple data structures are easy to test

Design your props to be simple, focused, and representative of what the component needs to render. Keep them immutable and make sure they conform to `Equatable` for optimal performance.
