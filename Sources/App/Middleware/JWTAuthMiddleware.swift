import Vapor
import JWT
import struct Foundation.UUID

/// Payload for server-issued JWT tokens
struct ServerJWTPayload: JWTPayload {
    var sub: SubjectClaim       // user UUID
    var exp: ExpirationClaim    // expiration
    var iat: IssuedAtClaim      // issued at
    var jti: IDClaim            // unique token identifier

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.exp.verifyNotExpired()
    }
}

/// In-memory token blacklist for revoked JWTs.
/// Uses jti (JWT ID) to track blacklisted tokens until they expire.
actor TokenBlacklist {
    static let shared = TokenBlacklist()

    /// Maps jti -> expiration date
    private var blacklistedTokens: [String: Date] = [:]

    /// Add a token to the blacklist. It will be automatically cleaned up after expiration.
    func blacklist(jti: String, expiration: Date) {
        cleanupExpired()
        blacklistedTokens[jti] = expiration
    }

    /// Check if a token has been blacklisted.
    func isBlacklisted(jti: String) -> Bool {
        cleanupExpired()
        return blacklistedTokens[jti] != nil
    }

    /// Remove all expired entries from the blacklist.
    private func cleanupExpired() {
        let now = Date()
        blacklistedTokens = blacklistedTokens.filter { _, expiration in
            expiration > now
        }
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

        do {
            let payload = try await request.jwt.verify(bearerToken, as: ServerJWTPayload.self)
            guard let userID = UUID(uuidString: payload.sub.value) else {
                throw Abort(.unauthorized, reason: "Invalid user ID in token")
            }

            // Check if the token has been blacklisted (e.g. after logout)
            if await TokenBlacklist.shared.isBlacklisted(jti: payload.jti.value) {
                throw Abort(.unauthorized, reason: "Token has been revoked")
            }

            request.storage[AuthenticatedUserKey.self] = userID
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or expired token")
        }

        return try await next.respond(to: request)
    }
}

// MARK: - Request Storage Key
struct AuthenticatedUserKey: StorageKey {
    typealias Value = UUID
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
}
