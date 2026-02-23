import Vapor

// MARK: - Paginated Response
struct PagedResponse<T: Content>: Content {
    let data: [T]
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int
}

// MARK: - Error Response
struct ErrorResponse: Content {
    let error: Bool
    let reason: String
    let code: String?

    init(reason: String, code: String? = nil) {
        self.error = true
        self.reason = reason
        self.code = code
    }
}

// MARK: - Success Response
struct SuccessResponse: Content {
    let success: Bool
    let message: String?

    init(message: String? = nil) {
        self.success = true
        self.message = message
    }
}
