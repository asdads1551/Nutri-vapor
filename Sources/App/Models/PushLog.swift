import Fluent
import Vapor

final class PushLog: Model, Content, @unchecked Sendable {
    static let schema = "push_logs"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "type") var type: PushType
    @Field(key: "title") var title: String
    @Field(key: "body") var body: String
    @Field(key: "status") var status: PushStatus
    @Field(key: "sent_at") var sentAt: Date
    @Field(key: "clicked_at") var clickedAt: Date?

    init() {}
}
