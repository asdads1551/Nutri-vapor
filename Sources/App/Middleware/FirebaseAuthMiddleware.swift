import Vapor
import JWT

/// Middleware to verify Firebase ID Tokens using Google's public JWKS certificates.
/// Used for /auth/register and /auth/login endpoints.
struct FirebaseAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let bearerToken = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing Firebase ID token")
        }

        let parts = bearerToken.split(separator: ".")
        guard parts.count == 3 else {
            throw Abort(.unauthorized, reason: "Invalid Firebase token format")
        }

        // Decode header to verify alg
        guard let headerData = base64URLDecode(String(parts[0])),
              let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              let alg = header["alg"] as? String, alg == "RS256" else {
            throw Abort(.unauthorized, reason: "Invalid Firebase token header")
        }

        // Decode payload for claim verification
        guard let payloadData = base64URLDecode(String(parts[1])),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw Abort(.unauthorized, reason: "Cannot decode Firebase token payload")
        }

        // Verify issuer (must match Firebase project)
        let expectedIssuer = "https://securetoken.google.com/\(APIConstants.firebaseProjectId)"
        guard let iss = payload["iss"] as? String, iss == expectedIssuer else {
            throw Abort(.unauthorized, reason: "Firebase token issuer mismatch")
        }

        // Verify audience (must be Firebase project ID)
        guard let aud = payload["aud"] as? String, aud == APIConstants.firebaseProjectId else {
            throw Abort(.unauthorized, reason: "Firebase token audience mismatch")
        }

        // Verify subject (user UID) exists and is non-empty
        guard let sub = payload["sub"] as? String, !sub.isEmpty else {
            throw Abort(.unauthorized, reason: "Firebase token missing subject")
        }

        // Verify expiration
        guard let exp = payload["exp"] as? TimeInterval,
              Date(timeIntervalSince1970: exp) > Date() else {
            throw Abort(.unauthorized, reason: "Firebase token expired")
        }

        // Verify issued-at is in the past
        guard let iat = payload["iat"] as? TimeInterval,
              Date(timeIntervalSince1970: iat) <= Date() else {
            throw Abort(.unauthorized, reason: "Firebase token issued in the future")
        }

        // Verify auth_time is in the past
        if let authTime = payload["auth_time"] as? TimeInterval {
            guard Date(timeIntervalSince1970: authTime) <= Date() else {
                throw Abort(.unauthorized, reason: "Firebase token auth_time in the future")
            }
        }

        // Verify signature using Google JWKS
        let firebaseKeys = try await FirebaseJWKSManager.shared.getKeys(
            client: request.client,
            logger: request.logger
        )
        do {
            _ = try await firebaseKeys.verify(bearerToken, as: FirebaseJWTPayload.self)
        } catch {
            request.logger.warning("Firebase token signature verification failed: \(error)")
            throw Abort(.unauthorized, reason: "Firebase token signature verification failed")
        }

        let email = payload["email"] as? String

        request.storage[FirebaseUserKey.self] = FirebaseTokenPayload(
            uid: sub,
            email: email
        )

        return try await next.respond(to: request)
    }

    private func base64URLDecode(_ string: String) -> Data? {
        Self.base64URLDecode(string)
    }

    // MARK: - Static helpers

    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        return Data(base64Encoded: base64)
    }

    /// Verify a Firebase ID token from the request body (without middleware).
    /// Returns a `FirebaseTokenPayload` on success.
    static func verifyToken(_ token: String, client: Client, logger: Logger) async throws -> FirebaseTokenPayload {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            throw Abort(.unauthorized, reason: "Invalid Firebase token format")
        }

        // Decode header to verify alg
        guard let headerData = base64URLDecode(String(parts[0])),
              let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              let alg = header["alg"] as? String, alg == "RS256" else {
            throw Abort(.unauthorized, reason: "Invalid Firebase token header")
        }

        // Decode payload for claim verification
        guard let payloadData = base64URLDecode(String(parts[1])),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw Abort(.unauthorized, reason: "Cannot decode Firebase token payload")
        }

        // Verify issuer
        let expectedIssuer = "https://securetoken.google.com/\(APIConstants.firebaseProjectId)"
        guard let iss = payload["iss"] as? String, iss == expectedIssuer else {
            throw Abort(.unauthorized, reason: "Firebase token issuer mismatch")
        }

        // Verify audience
        guard let aud = payload["aud"] as? String, aud == APIConstants.firebaseProjectId else {
            throw Abort(.unauthorized, reason: "Firebase token audience mismatch")
        }

        // Verify subject (user UID)
        guard let sub = payload["sub"] as? String, !sub.isEmpty else {
            throw Abort(.unauthorized, reason: "Firebase token missing subject")
        }

        // Verify expiration
        guard let exp = payload["exp"] as? TimeInterval,
              Date(timeIntervalSince1970: exp) > Date() else {
            throw Abort(.unauthorized, reason: "Firebase token expired")
        }

        // Verify issued-at is in the past
        guard let iat = payload["iat"] as? TimeInterval,
              Date(timeIntervalSince1970: iat) <= Date() else {
            throw Abort(.unauthorized, reason: "Firebase token issued in the future")
        }

        // Verify auth_time is in the past
        if let authTime = payload["auth_time"] as? TimeInterval {
            guard Date(timeIntervalSince1970: authTime) <= Date() else {
                throw Abort(.unauthorized, reason: "Firebase token auth_time in the future")
            }
        }

        // Verify signature using Google JWKS
        let firebaseKeys = try await FirebaseJWKSManager.shared.getKeys(
            client: client,
            logger: logger
        )
        do {
            _ = try await firebaseKeys.verify(token, as: FirebaseJWTPayload.self)
        } catch {
            logger.warning("Firebase token signature verification failed: \(error)")
            throw Abort(.unauthorized, reason: "Firebase token signature verification failed")
        }

        let email = payload["email"] as? String
        return FirebaseTokenPayload(uid: sub, email: email)
    }
}

// MARK: - Firebase JWT Payload for signature verification
struct FirebaseJWTPayload: JWTPayload {
    var sub: SubjectClaim
    var exp: ExpirationClaim
    var iss: IssuerClaim
    var aud: AudienceClaim
    var iat: IssuedAtClaim

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.exp.verifyNotExpired()
    }
}

// MARK: - JWKS Manager
/// Thread-safe cache for Google's JWKS public keys used to verify Firebase tokens.
actor FirebaseJWKSManager {
    static let shared = FirebaseJWKSManager()

    private var keyCollection: JWTKeyCollection?
    private var cacheExpiry: Date = .distantPast

    func getKeys(client: Client, logger: Logger) async throws -> JWTKeyCollection {
        if let keys = keyCollection, Date() < cacheExpiry {
            return keys
        }

        let response: ClientResponse
        do {
            response = try await client.get(URI(string: APIConstants.googleJWKSURL))
        } catch {
            logger.error("Failed to fetch Google JWKS: \(error)")
            if let keys = keyCollection {
                logger.warning("Using expired Firebase JWKS cache as fallback")
                return keys
            }
            throw Abort(.internalServerError, reason: "Unable to verify Firebase token: JWKS unavailable")
        }

        guard response.status == .ok, let body = response.body else {
            if let keys = keyCollection {
                logger.warning("Using expired Firebase JWKS cache as fallback (HTTP \(response.status))")
                return keys
            }
            throw Abort(.internalServerError, reason: "Unable to verify Firebase token: JWKS unavailable")
        }

        let jwks = try JSONDecoder().decode(JWKS.self, from: Data(buffer: body))
        let newKeys = JWTKeyCollection()
        try await newKeys.add(jwks: jwks)

        self.keyCollection = newKeys

        // Parse Cache-Control max-age, default to 1 hour
        var ttl: TimeInterval = 3600
        if let cacheControl = response.headers.first(name: .cacheControl),
           let maxAgeRange = cacheControl.range(of: "max-age=") {
            let afterMaxAge = cacheControl[maxAgeRange.upperBound...]
            let digits = afterMaxAge.prefix(while: { $0.isNumber })
            if let parsed = TimeInterval(digits) {
                ttl = parsed
            }
        }
        self.cacheExpiry = Date().addingTimeInterval(ttl)

        logger.info("Refreshed Firebase JWKS keys (\(jwks.keys.count) keys, TTL: \(Int(ttl))s)")
        return newKeys
    }
}

// MARK: - Request Storage Key
struct FirebaseUserKey: StorageKey {
    typealias Value = FirebaseTokenPayload
}

extension Request {
    var firebaseUser: FirebaseTokenPayload? {
        storage[FirebaseUserKey.self]
    }
}
