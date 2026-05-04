import Foundation
import HayabusaLocalPolicy
import Hummingbird

/// request-scoped Hummingbird context: couples decode limits to ``LocalServiceLimits`` single source of truth.
struct HayabusaRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage

    init(source: ApplicationRequestContextSource) {
        self.coreContext = .init(source: source)
    }

    var maxUploadSize: Int { LocalServiceLimits.localDeveloper.maxJsonBodyBytes }
}
