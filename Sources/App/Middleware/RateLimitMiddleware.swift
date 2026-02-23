import Vapor

/// Simple in-memory rate limiter.
/// For production, use Redis-backed rate limiting.
actor RateLimitStore {
    private var requests: [String: [Date]] = [:]
    private let maxRequests: Int
    private let window: TimeInterval // seconds

    init(maxRequests: Int, windowSeconds: TimeInterval = 60) {
        self.maxRequests = maxRequests
        self.window = windowSeconds
    }

    func checkLimit(for key: String) -> Bool {
        let now = Date()
        let cutoff = now.addingTimeInterval(-window)

        // Clean old entries
        var reqs = requests[key, default: []]
        reqs = reqs.filter { $0 > cutoff }

        if reqs.count >= maxRequests {
            requests[key] = reqs
            return false // rate limited
        }

        reqs.append(now)
        requests[key] = reqs
        return true // allowed
    }
}

struct RateLimitMiddleware: AsyncMiddleware {
    let store: RateLimitStore

    init(maxRequests: Int = 100, windowSeconds: TimeInterval = 60) {
        self.store = RateLimitStore(maxRequests: maxRequests, windowSeconds: windowSeconds)
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // Use IP address or authenticated user ID as the rate limit key
        let key: String
        if let userID = request.storage[AuthenticatedUserKey.self] {
            key = "user:\(userID)"
        } else {
            key = "ip:\(request.remoteAddress?.description ?? "unknown")"
        }

        let allowed = await store.checkLimit(for: key)
        guard allowed else {
            throw Abort(.tooManyRequests, reason: "Rate limit exceeded. Try again later.")
        }

        return try await next.respond(to: request)
    }
}
