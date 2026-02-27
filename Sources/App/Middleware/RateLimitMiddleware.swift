import Vapor

/// Simple in-memory rate limiter with periodic cleanup.
/// For production with multiple instances, replace with Redis-backed rate limiting.
actor RateLimitStore {
    private var requests: [String: [Date]] = [:]
    private let maxRequests: Int
    private let window: TimeInterval // seconds
    private var lastCleanup = Date()
    private let cleanupInterval: TimeInterval = 300 // 5 minutes

    init(maxRequests: Int, windowSeconds: TimeInterval = 60) {
        self.maxRequests = maxRequests
        self.window = windowSeconds
    }

    /// Returns remaining seconds until the window resets, or nil if allowed.
    func checkLimit(for key: String) -> Int? {
        let now = Date()
        let cutoff = now.addingTimeInterval(-window)

        // Clean old entries for this key
        var reqs = requests[key, default: []]
        reqs = reqs.filter { $0 > cutoff }

        if reqs.count >= maxRequests {
            requests[key] = reqs
            // Calculate Retry-After: seconds until oldest request expires
            let retryAfter = reqs.first.map { Int(ceil($0.timeIntervalSince(cutoff))) } ?? Int(window)
            return retryAfter // rate limited — return retry seconds
        }

        reqs.append(now)
        requests[key] = reqs

        // Periodic cleanup of stale keys
        if now.timeIntervalSince(lastCleanup) > cleanupInterval {
            let globalCutoff = now.addingTimeInterval(-window)
            requests = requests.filter { !$0.value.allSatisfy { $0 <= globalCutoff } }
            lastCleanup = now
        }

        return nil // allowed
    }
}

struct RateLimitMiddleware: AsyncMiddleware {
    let store: RateLimitStore
    private let windowSeconds: TimeInterval

    init(maxRequests: Int = 100, windowSeconds: TimeInterval = 60) {
        self.store = RateLimitStore(maxRequests: maxRequests, windowSeconds: windowSeconds)
        self.windowSeconds = windowSeconds
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // Prefer X-Forwarded-For for clients behind a reverse proxy, fallback to remote address
        let key: String
        if let userID = request.storage[AuthenticatedUserKey.self] {
            key = "user:\(userID)"
        } else {
            let ip = request.headers.first(name: "X-Forwarded-For")?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
                ?? request.remoteAddress?.description
                ?? "unknown"
            key = "ip:\(ip)"
        }

        if let retryAfter = await store.checkLimit(for: key) {
            var headers = HTTPHeaders()
            headers.add(name: "Retry-After", value: "\(retryAfter)")
            throw Abort(.tooManyRequests, headers: headers, reason: "Rate limit exceeded. Try again in \(retryAfter) seconds.")
        }

        return try await next.respond(to: request)
    }
}
