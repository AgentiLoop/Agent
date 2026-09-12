import Foundation

/// One value per `APIProvider`, with a non-optional subscript so SwiftUI bindings
/// (`$viewModel.models[.openAI]`) work directly.
///
/// `load` supplies the initial value for every provider (UserDefaults / Keychain / registry default);
/// `persist` runs after every write. Neither closure may touch the view model — they only talk to
/// singletons — so the store can be built as a stored-property initializer.
@MainActor
struct ProviderKeyed<Value> {
    private var values: [APIProvider: Value]
    private let persist: ((APIProvider, Value) -> Void)?

    init(load: (APIProvider) -> Value, persist: ((APIProvider, Value) -> Void)? = nil) {
        self.values = Dictionary(uniqueKeysWithValues: APIProvider.allCases.map { ($0, load($0)) })
        self.persist = persist
    }

    subscript(provider: APIProvider) -> Value {
        get { values[provider]! }
        set {
            values[provider] = newValue
            persist?(provider, newValue)
        }
    }
}
