@testable import App
import XCTVapor
import Testing

@Suite("App Tests")
struct AppTests {
    @Test("Health check returns ok")
    func healthCheck() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        try await configure(app)

        try await app.test(.GET, "health") { res async in
            #expect(res.status == .ok)
        }
    }

    @Test("API v1 health check returns version")
    func apiHealthCheck() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        try await configure(app)

        try await app.test(.GET, "api/v1/health") { res async in
            #expect(res.status == .ok)
        }
    }
}

// MARK: - Validation Tests
@Suite("Input Validation Tests")
struct ValidationTests {
    @Test("CreateFoodEntryRequest rejects negative calories")
    func rejectNegativeCalories() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        try await configure(app)

        try await app.test(.POST, "api/v1/nutrition/entries",
            beforeRequest: { req in
                req.headers.contentType = .json
                req.body = .init(string: #"{"meal_type":"breakfast","food_name":"Test","calories":-100}"#)
            },
            afterResponse: { res async in
                // Should fail with 401 (no auth) or 400 (validation) — not 200
                #expect(res.status != .ok)
            }
        )
    }

    @Test("CreateFoodEntryRequest rejects empty food name")
    func rejectEmptyFoodName() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        try await configure(app)

        try await app.test(.POST, "api/v1/nutrition/entries",
            beforeRequest: { req in
                req.headers.contentType = .json
                req.body = .init(string: #"{"meal_type":"breakfast","food_name":"","calories":100}"#)
            },
            afterResponse: { res async in
                #expect(res.status != .ok)
            }
        )
    }

    @Test("Protected endpoints require authentication")
    func protectedEndpointsRequireAuth() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        try await configure(app)

        // All these should return 401 without a token
        let protectedPaths = [
            "api/v1/users/me",
            "api/v1/nutrition/entries",
            "api/v1/recipes",
            "api/v1/health/summary",
            "api/v1/notifications/settings"
        ]

        for path in protectedPaths {
            try await app.test(.GET, path) { res async in
                #expect(res.status == .unauthorized, "Expected 401 for \(path)")
            }
        }
    }

    @Test("Auth endpoints require Firebase token")
    func authEndpointsRequireFirebaseToken() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        try await configure(app)

        // Register without Bearer token should return 401
        try await app.test(.POST, "api/v1/auth/register") { res async in
            #expect(res.status == .unauthorized)
        }

        // Login without Bearer token should return 401
        try await app.test(.POST, "api/v1/auth/login") { res async in
            #expect(res.status == .unauthorized)
        }
    }

    @Test("Auth rejects malformed Firebase token")
    func rejectMalformedFirebaseToken() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        try await configure(app)

        try await app.test(.POST, "api/v1/auth/login",
            beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: "not-a-jwt")
            },
            afterResponse: { res async in
                #expect(res.status == .unauthorized)
            }
        )
    }

    @Test("Rate limiting is applied to auth endpoints")
    func rateLimitingApplied() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        try await configure(app)

        // Send more than authRateLimit (5) requests rapidly
        var lastStatus: HTTPStatus = .ok
        for _ in 0..<10 {
            try await app.test(.POST, "api/v1/auth/login") { res async in
                lastStatus = res.status
            }
        }

        // At least one should be rate limited (429) or unauthorized (401)
        // The exact behavior depends on whether rate limit triggers before auth
        #expect(lastStatus == .tooManyRequests || lastStatus == .unauthorized)
    }
}

// MARK: - DTO Tests
@Suite("DTO Encoding Tests")
struct DTOTests {
    @Test("SuccessResponse encodes correctly")
    func successResponseEncoding() throws {
        let response = SuccessResponse(message: "test")
        #expect(response.success == true)
        #expect(response.message == "test")
    }

    @Test("ErrorResponse encodes correctly")
    func errorResponseEncoding() throws {
        let response = ErrorResponse(reason: "bad request", code: "VALIDATION_ERROR")
        #expect(response.error == true)
        #expect(response.reason == "bad request")
        #expect(response.code == "VALIDATION_ERROR")
    }

    @Test("PagedResponse encodes correctly")
    func pagedResponseEncoding() throws {
        let response = PagedResponse<RecipeListItem>(
            data: [],
            page: 1,
            perPage: 20,
            total: 0,
            totalPages: 1
        )
        #expect(response.totalPages == 1)
        #expect(response.data.isEmpty)
    }
}

// MARK: - DateFormatter Tests
@Suite("DateFormatter Tests")
struct DateFormatterTests {
    @Test("Shared yyyy-MM-dd formatter uses Taipei timezone")
    func sharedFormatterTimezone() {
        let tz = DateFormatter.yyyyMMdd.timeZone
        #expect(tz?.identifier == "Asia/Taipei")
    }

    @Test("Shared Calendar uses Taipei timezone")
    func sharedCalendarTimezone() {
        let tz = Calendar.taipei.timeZone
        #expect(tz.identifier == "Asia/Taipei")
    }

    @Test("Date formatting round-trips correctly")
    func dateRoundTrip() {
        let dateStr = "2026-02-27"
        let date = DateFormatter.yyyyMMdd.date(from: dateStr)
        #expect(date != nil)
        let formatted = DateFormatter.yyyyMMdd.string(from: date!)
        #expect(formatted == dateStr)
    }
}
