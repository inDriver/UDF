# Service Component

Background components that handle business logic and side effects.

## Overview

`ServiceComponent` is a protocol for components that run on background queues and handle business logic, side effects, and external service interactions. Service components are essential for keeping your application logic separate from UI concerns and for handling asynchronous operations.

### Key Characteristics

- **Background Execution**: Runs on `.global()` queue by default
- **Side Effects**: Handles API calls, file operations, and other side effects
- **Business Logic**: Contains application business logic
- **Long-Lived**: Often live for the entire application lifecycle

## Example

```swift
class UserService: ServiceComponent {
    let disposer = Disposer()
    var props: UserServiceProps = UserServiceProps()
    
    private let apiClient: APIClient
    private let store: Store<AppState>
    
    init(apiClient: APIClient, store: Store<AppState>) {
        self.apiClient = apiClient
        self.store = store
        
        // Connect to store to listen for actions
        connect(to: store) { state in
            UserServiceProps(
                shouldLoadUser: state.user == nil && !state.isLoading,
                userId: state.pendingUserId
            )
        }
    }
    
    func updateProps() {
        if props.shouldLoadUser, let userId = props.userId {
            loadUser(userId: userId)
        }
    }
    
    private func loadUser(userId: String) {
        // Dispatch loading action
        store.dispatch(LoadUserAction(userId: userId))
        
        // Make API call
        apiClient.fetchUser(id: userId) { [weak self] result in
            switch result {
            case .success(let user):
                self?.store.dispatch(UserLoadedAction(user: user))
            case .failure(let error):
                self?.store.dispatch(UserLoadErrorAction(message: error.localizedDescription))
            }
        }
    }
}

struct UserServiceProps: Equatable {
    let shouldLoadUser: Bool
    let userId: String?
}
```

## Service Component Types

### API Service Components
Handle network requests and API interactions:

```swift
class APIService: ServiceComponent {
    let disposer = Disposer()
    var props: APIServiceProps = APIServiceProps()
    
    private let networkClient: NetworkClient
    private let store: Store<AppState>
    
    init(networkClient: NetworkClient, store: Store<AppState>) {
        self.networkClient = networkClient
        self.store = store
        
        connect(to: store) { state in
            APIServiceProps(
                pendingRequests: state.pendingAPIRequests,
                isOnline: state.networkStatus.isOnline
            )
        }
    }
    
    func updateProps() {
        guard props.isOnline else { return }
        
        for request in props.pendingRequests {
            executeRequest(request)
        }
    }
    
    private func executeRequest(_ request: APIRequest) {
        store.dispatch(APIRequestStartedAction(requestId: request.id))
        
        networkClient.execute(request) { [weak self] result in
            switch result {
            case .success(let data):
                self?.store.dispatch(APIRequestCompletedAction(
                    requestId: request.id,
                    data: data
                ))
            case .failure(let error):
                self?.store.dispatch(APIRequestFailedAction(
                    requestId: request.id,
                    error: error
                ))
            }
        }
    }
}
```

### Data Persistence Service Components
Handle local data storage and persistence:

```swift
class DataPersistenceService: ServiceComponent {
    let disposer = Disposer()
    var props: DataPersistenceProps = DataPersistenceProps()
    
    private let storage: LocalStorage
    private let store: Store<AppState>
    
    init(storage: LocalStorage, store: Store<AppState>) {
        self.storage = storage
        self.store = store
        
        connect(to: store) { state in
            DataPersistenceProps(
                shouldSaveUser: state.user != nil && state.user != state.lastSavedUser,
                shouldLoadUser: state.user == nil && !state.isLoading
            )
        }
    }
    
    func updateProps() {
        if props.shouldSaveUser {
            saveUser()
        } else if props.shouldLoadUser {
            loadUser()
        }
    }
    
    private func saveUser() {
        // Save user to local storage
        storage.saveUser(store.state.user) { [weak self] result in
            switch result {
            case .success:
                self?.store.dispatch(UserSavedAction())
            case .failure(let error):
                self?.store.dispatch(UserSaveErrorAction(message: error.localizedDescription))
            }
        }
    }
    
    private func loadUser() {
        // Load user from local storage
        storage.loadUser { [weak self] result in
            switch result {
            case .success(let user):
                self?.store.dispatch(UserLoadedAction(user: user))
            case .failure:
                // User not found in local storage, will be loaded from API
                break
            }
        }
    }
}
```

### Analytics Service Components
Handle analytics and tracking:

```swift
class AnalyticsService: ServiceComponent {
    let disposer = Disposer()
    var props: AnalyticsProps = AnalyticsProps()
    
    private let analyticsProvider: AnalyticsProvider
    private let store: Store<AppState>
    
    init(analyticsProvider: AnalyticsProvider, store: Store<AppState>) {
        self.analyticsProvider = analyticsProvider
        self.store = store
        
        // Listen to actions for tracking
        connect(to: store) { state in
            AnalyticsProps(
                currentScreen: state.currentScreen,
                user: state.user
            )
        }
    }
    
    func updateProps() {
        // Track screen views
        analyticsProvider.trackScreen(props.currentScreen)
        
        // Track user properties
        if let user = props.user {
            analyticsProvider.setUserProperties(user.analyticsProperties)
        }
    }
}
```

## Service Component Best Practices

### Keep Business Logic Separate
Service components should focus on business logic, not UI concerns:

```swift
// Good - focused on business logic
class PaymentService: ServiceComponent {
    func updateProps() {
        if props.shouldProcessPayment {
            processPayment(props.paymentData)
        }
    }
    
    private func processPayment(_ paymentData: PaymentData) {
        // Business logic here
        paymentProcessor.process(paymentData) { [weak self] result in
            // Dispatch appropriate actions
        }
    }
}

// Avoid - mixing UI concerns
class BadPaymentService: ServiceComponent {
    func updateProps() {
        if props.shouldProcessPayment {
            // Don't do UI updates in service components
            showLoadingIndicator()
            processPayment(props.paymentData)
        }
    }
}
```

### Handle Errors Gracefully
Always handle errors and dispatch appropriate actions:

```swift
class UserService: ServiceComponent {
    private func loadUser(userId: String) {
        store.dispatch(LoadUserAction(userId: userId))
        
        apiClient.fetchUser(id: userId) { [weak self] result in
            switch result {
            case .success(let user):
                self?.store.dispatch(UserLoadedAction(user: user))
            case .failure(let error):
                // Always handle errors
                self?.store.dispatch(UserLoadErrorAction(
                    message: error.localizedDescription
                ))
            }
        }
    }
}
```

### Use Appropriate Queues
Service components run on background queues by default, but you can customize:

```swift
class CustomService: ServiceComponent {
    // Override queue for specific needs
    var queue: DispatchQueue { 
        return DispatchQueue(label: "com.app.custom-service", qos: .utility)
    }
}
```

### Manage Dependencies
Inject dependencies rather than creating them:

```swift
class UserService: ServiceComponent {
    private let apiClient: APIClient
    private let storage: LocalStorage
    private let analytics: AnalyticsProvider
    
    init(
        apiClient: APIClient,
        storage: LocalStorage,
        analytics: AnalyticsProvider,
        store: Store<AppState>
    ) {
        self.apiClient = apiClient
        self.storage = storage
        self.analytics = analytics
        super.init(store: store)
    }
}
```

## Service Component Lifecycle

### Initialization
Service components are typically initialized early in the application lifecycle:

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var store: Store<AppState>!
    var services: [ServiceComponent] = []
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Create store
        store = Store(state: AppState(), reducer: appReducer)
        
        // Initialize services
        let userService = UserService(apiClient: apiClient, store: store)
        let analyticsService = AnalyticsService(provider: analyticsProvider, store: store)
        
        services = [userService, analyticsService]
        
        return true
    }
}
```

### Cleanup
Service components are automatically cleaned up when they're deallocated, but you can add custom cleanup:

```swift
class NetworkService: ServiceComponent {
    private var activeRequests: [String: URLSessionDataTask] = [:]
    
    deinit {
        // Cancel all active requests
        activeRequests.values.forEach { $0.cancel() }
    }
    
    private func executeRequest(_ request: APIRequest) {
        let task = networkClient.execute(request) { [weak self] result in
            self?.activeRequests.removeValue(forKey: request.id)
            // Handle result
        }
        
        activeRequests[request.id] = task
    }
}
```

## Testing Service Components

Service components can be tested by mocking their dependencies:

```swift
class UserServiceTests: XCTestCase {
    var service: UserService!
    var mockAPIClient: MockAPIClient!
    var mockStore: MockStore!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        mockStore = MockStore()
        service = UserService(apiClient: mockAPIClient, store: mockStore)
    }
    
    func testLoadUser() {
        // Given
        let user = User(id: "123", name: "John")
        mockAPIClient.result = .success(user)
        
        // When
        service.updateProps()
        
        // Then
        XCTAssertTrue(mockStore.dispatchedActions.contains { $0 is LoadUserAction })
    }
}
```

## Summary

Service components are essential for handling business logic and side effects:

- **Background Execution**: Run on background queues for non-UI work
- **Side Effects**: Handle API calls, file operations, and external services
- **Business Logic**: Contain application business logic separate from UI
- **Long-Lived**: Often live for the entire application lifecycle
- **Testable**: Can be easily tested with mocked dependencies

Use service components to keep your application logic organized, testable, and separate from UI concerns. They are the backbone of handling side effects and business logic in a UDF application.
