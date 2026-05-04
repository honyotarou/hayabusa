import Foundation
import HayabusaLocalPolicy
import Hummingbird

/// request-scoped Hummingbird context: couples decode limits to ``LocalServiceLimits`` single source of truth.
package struct HayabusaRequestContext: RequestContext {
    package var coreContext: CoreRequestContextStorage

    package init(source: ApplicationRequestContextSource) {
        self.coreContext = .init(source: source)
    }

    package var maxUploadSize: Int { LocalServiceLimits.localDeveloper.maxJsonBodyBytes }
}
