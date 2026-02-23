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
            request.storage[AuthenticatedUserKey.self] = userID
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
