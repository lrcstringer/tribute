import SwiftUI

private struct StoreViewModelKey: EnvironmentKey {
    static let defaultValue: StoreViewModel? = nil
}

extension EnvironmentValues {
    var storeViewModel: StoreViewModel? {
        get { self[StoreViewModelKey.self] }
        set { self[StoreViewModelKey.self] = newValue }
    }
}
