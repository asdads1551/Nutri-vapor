import Fluent
import SQLKit

struct RenameHealthActiveCalToActiveCalories: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            throw FluentError.idRequired
        }
        try await sql.raw("ALTER TABLE health_sync_logs RENAME COLUMN active_cal TO active_calories").run()
    }

    func revert(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            throw FluentError.idRequired
        }
        try await sql.raw("ALTER TABLE health_sync_logs RENAME COLUMN active_calories TO active_cal").run()
    }
}
