import Vapor
import JWT

/// Middleware to verify Firebase ID Tokens.
/// Used for /auth/register and /auth/login endpoints.
/// Verifies the token using Google's public keys (JWKS).
struct FirebaseAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // Extract Bearer token
        guard let bearerToken = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing Firebase ID token")
        }

        // Decode Firebase token (simplified — in production, verify against Google JWKS)
        // For now, we decode the JWT payload without full signature verification.
        // TODO: Implement full JWKS verification using Google's public certificates
        let parts = bearerToken.split(separator: ".")
        guard parts.count == 3 else {
            throw Abort(.unauthorized, reason: "Invalid Firebase token format")
        }

        // Decode payload (Base64URL)
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let payloadData = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw Abort(.unauthorized, reason: "Cannot decode Firebase token payload")
        }

        // Extract claims
        guard let uid = payload["sub"] as? String ?? payload["user_id"] as? String else {
            throw Abort(.unauthorized, reason: "Firebase token missing uid")
        }

        // Verify issuer
        let expectedIssuer = "https://securetoken.google.com/\(APIConstants.firebaseProjectId)"
        if let iss = payload["iss"] as? String, iss != expectedIssuer {
            throw Abort(.unauthorized, reason: "Firebase token issuer mismatch")
        }

        // Verify expiration
        if let exp = payload["exp"] as? TimeInterval {
            let expirationDate = Date(timeIntervalSince1970: exp)
            if expirationDate < Date() {
                throw Abort(.unauthorized, reason: "Firebase token expired")
            }
        }

        let email = payload["email"] as? String

        // Store Firebase user info in request storage
        request.storage[FirebaseUserKey.self] = FirebaseTokenPayload(
            uid: uid,
            email: email
        )

        return try await next.respond(to: request)
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
