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
