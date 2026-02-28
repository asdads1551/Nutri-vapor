import Vapor

/// Simple in-memory rate limiter.
/// For production, use Redis-backed rate limiting.
actor RateLimitStore {
    private var requests: [String: [Date]] = [:]
    private let maxRequests: Int
    private let window: TimeInterval // seconds
    private let maxKeys: Int = 10_000

    init(maxRequests: Int, windowSeconds: TimeInterval = 60) {
        self.maxRequests = maxRequests
        self.window = windowSeconds
    }

    func checkLimit(for key: String) -> Bool {
        let now = Date()
        let cutoff = now.addingTimeInterval(-window)

        // Clean old entries for this key
        var reqs = requests[key, default: []]
        reqs = reqs.filter { $0 > cutoff }

        // If timestamps array is empty after cleanup, remove the key entirely
        if reqs.isEmpty && requests[key] != nil {
            requests.removeValue(forKey: key)
        }

        if reqs.count >= maxRequests {
            requests[key] = reqs
            return false // rate limited
        }

        reqs.append(now)
        requests[key] = reqs

        // Enforce maximum number of tracked keys to prevent unbounded memory growth
        if requests.count > maxKeys {
            evictOldestEntries()
        }

        return true // allowed
    }

    /// Remove the oldest entries when the key limit is exceeded.
    /// Removes keys with the oldest last-access timestamps.
    private func evictOldestEntries() {
        let targetSize = maxKeys / 2
        // Sort keys by their most recent timestamp (oldest first)
        let sorted = requests.sorted { lhs, rhs in
            let lhsLatest = lhs.value.last ?? .distantPast
            let rhsLatest = rhs.value.last ?? .distantPast
            return lhsLatest < rhsLatest
        }
        let keysToRemove = sorted.prefix(requests.count - targetSize)
        for (key, _) in keysToRemove {
            requests.removeValue(forKey: key)
        }
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
            // Check X-Forwarded-For header first (take the first IP in the chain),
            // then fall back to remoteAddress
            if let forwarded = request.headers.first(name: "X-Forwarded-For") {
                let firstIP = forwarded.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? "unknown"
                key = "ip:\(firstIP)"
            } else {
                key = "ip:\(request.remoteAddress?.description ?? "unknown")"
            }
        }

        let allowed = await store.checkLimit(for: key)
        guard allowed else {
            throw Abort(.tooManyRequests, reason: "Rate limit exceeded. Try again later.")
        }

        return try await next.respond(to: request)
    }
}
