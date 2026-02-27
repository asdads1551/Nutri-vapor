import Vapor
import JWT

/// Payload for server-issued JWT tokens
struct ServerJWTPayload: JWTPayload {
    var sub: SubjectClaim       // user UUID
    var exp: ExpirationClaim    // expiration
    var iat: IssuedAtClaim      // issued at

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.exp.verifyNotExpired()
    }
}

// MARK: - Token Blacklist
/// In-memory token blacklist for logout/revocation.
/// For production with multiple instances, replace with Redis-backed implementation.
actor TokenBlacklist {
    static let shared = TokenBlacklist()

    /// Maps token → expiry date (auto-cleanup expired entries)
    private var revokedTokens: [String: Date] = [:]
    private var lastCleanup = Date()
    private let cleanupInterval: TimeInterval = 300 // 5 minutes

    func revoke(token: String, expiry: Date) {
        revokedTokens[token] = expiry
        cleanupIfNeeded()
    }

    func isRevoked(_ token: String) -> Bool {
        cleanupIfNeeded()
        return revokedTokens[token] != nil
    }

    private func cleanupIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastCleanup) > cleanupInterval else { return }
        revokedTokens = revokedTokens.filter { $0.value > now }
        lastCleanup = now
    }
}

/// Middleware to verify server-issued JWT tokens.
/// Used for all business API endpoints after initial login.
struct JWTAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // Extract Bearer token
        guard let bearerToken = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing authorization token")
        }

        // Check token blacklist (revoked on logout)
        if await TokenBlacklist.shared.isRevoked(bearerToken) {
            throw Abort(.unauthorized, reason: "Token has been revoked")
        }

        do {
            let payload = try await request.jwt.verify(bearerToken, as: ServerJWTPayload.self)
            guard let userID = UUID(uuidString: payload.sub.value) else {
                throw Abort(.unauthorized, reason: "Invalid user ID in token")
            }
            request.storage[AuthenticatedUserKey.self] = userID
            request.storage[BearerTokenKey.self] = bearerToken
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or expired token")
        }

        return try await next.respond(to: request)
    }
}

// MARK: - Request Storage Keys
struct AuthenticatedUserKey: StorageKey {
    typealias Value = UUID
}

struct BearerTokenKey: StorageKey {
    typealias Value = String
}

extension Request {
    /// The authenticated user's UUID from the JWT token
    var authenticatedUserID: UUID {
        get throws {
            guard let userID = storage[AuthenticatedUserKey.self] else {
                throw Abort(.unauthorized, reason: "Not authenticated")
            }
            return userID
        }
    }

    /// The raw Bearer token from the current request
    var bearerToken: String? {
        storage[BearerTokenKey.self]
    }
}
