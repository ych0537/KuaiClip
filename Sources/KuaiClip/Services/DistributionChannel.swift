import Foundation

enum DistributionChannel {
    static var isAppStore: Bool {
#if APP_STORE
        true
#else
        false
#endif
    }
}
