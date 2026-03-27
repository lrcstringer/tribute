import Foundation
import AuthenticationServices

nonisolated struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let result: APIResult<T>
}

nonisolated struct APIResult<T: Decodable & Sendable>: Decodable, Sendable {
    let data: T
}

nonisolated struct AuthResponse: Codable, Sendable {
    let userId: String
    let displayName: String?
    let isNewUser: Bool
}

nonisolated struct CircleResponse: Codable, Sendable {
    let id: String
    let name: String
    let inviteCode: String
}

nonisolated struct CircleListItem: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let memberCount: Int
    let role: String
    let inviteCode: String
}

nonisolated struct CircleDetail: Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let memberCount: Int
    let inviteCode: String
    let createdAt: String
    let members: [CircleMemberInfo]
}

nonisolated struct CircleMemberInfo: Codable, Sendable, Identifiable {
    let userId: String
    let role: String
    let joinedAt: String

    var id: String { userId }
}

nonisolated struct JoinCircleResponse: Codable, Sendable {
    let id: String
    let name: String
    let alreadyMember: Bool
}

nonisolated struct SOSSendResponse: Codable, Sendable {
    let id: String
    let recipientCount: Int
}

nonisolated struct SOSItem: Codable, Sendable, Identifiable {
    let id: String
    let senderId: String
    let circleId: String
    let message: String
    let createdAt: String
    let isMine: Bool
}

nonisolated struct ShareLinkResponse: Codable, Sendable {
    let shareUrl: String
    let inviteCode: String
}

nonisolated struct SundaySummaryResponse: Codable, Sendable {
    let circleId: String
    let weekOf: String
    let totalMembers: Int
    let activeMembers: Int
    let averageScore: Double
    let topStreaks: [TopStreak]
}

nonisolated struct TopStreak: Codable, Sendable, Identifiable {
    let userId: String
    let streak: Int
    var id: String { userId }
}

nonisolated struct CircleHeatmapResponse: Codable, Sendable {
    let circleId: String
    let aggregatedData: [CircleHeatmapDay]
}

nonisolated struct CircleHeatmapDay: Codable, Sendable, Identifiable {
    let date: String
    let averageScore: Double
    let memberCount: Int
    var id: String { date }
}

nonisolated struct SOSContactsResponse: Codable, Sendable {
    let circleId: String
    let contactCount: Int
}

nonisolated struct SharedGratitudeItem: Codable, Sendable, Identifiable {
    let id: String
    let gratitudeText: String
    let isAnonymous: Bool
    let displayName: String?
    let sharedAt: String
    let isMine: Bool
}

nonisolated struct GratitudeWallResponse: Codable, Sendable {
    let circleId: String
    let weeksBack: Int
    let gratitudes: [SharedGratitudeItem]
}

nonisolated struct ShareGratitudeResponse: Codable, Sendable {
    let shared: [ShareGratitudeResult]
}

nonisolated struct ShareGratitudeResult: Codable, Sendable {
    let circleId: String
    let gratitudeId: String
}

nonisolated struct GratitudeNewCountResponse: Codable, Sendable {
    let circleId: String
    let newCount: Int
}

nonisolated struct GratitudeWeekCountResponse: Codable, Sendable {
    let circleId: String
    let weekCount: Int
}

@Observable
@MainActor
class APIService {
    static let shared = APIService()

    private(set) var userId: String?
    private(set) var isAuthenticated: Bool = false

    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var baseURL: String {
        Config.EXPO_PUBLIC_RORK_API_BASE_URL
    }

    init() {
        userId = UserDefaults.standard.string(forKey: "tribute_user_id")
        isAuthenticated = userId != nil
    }

    func signInWithApple(identityToken: String, authorizationCode: String, fullName: PersonNameComponents?, email: String?) async throws -> AuthResponse {
        var nameDict: [String: String?]? = nil
        if let fullName {
            nameDict = [
                "givenName": fullName.givenName,
                "familyName": fullName.familyName,
            ]
        }

        let body: [String: Any?] = [
            "identityToken": identityToken,
            "authorizationCode": authorizationCode,
            "fullName": nameDict as Any,
            "email": email,
        ]

        let result: AuthResponse = try await postMutation("auth.signInWithApple", body: body)

        userId = result.userId
        isAuthenticated = true
        UserDefaults.standard.set(result.userId, forKey: "tribute_user_id")

        return result
    }

    func signOut() {
        userId = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "tribute_user_id")
    }

    func createCircle(name: String, description: String = "") async throws -> CircleResponse {
        let body: [String: Any] = ["name": name, "description": description]
        return try await postMutation("circles.create", body: body)
    }

    func joinCircle(inviteCode: String) async throws -> JoinCircleResponse {
        let body: [String: Any] = ["inviteCode": inviteCode]
        return try await postMutation("circles.join", body: body)
    }

    func listCircles() async throws -> [CircleListItem] {
        return try await getQuery("circles.list")
    }

    func getCircleDetail(circleId: String) async throws -> CircleDetail {
        let input: [String: Any] = ["circleId": circleId]
        return try await getQuery("circles.getDetail", input: input)
    }

    func leaveCircle(circleId: String) async throws {
        let body: [String: Any] = ["circleId": circleId]
        let _: [String: Bool] = try await postMutation("circles.leave", body: body)
    }

    func sendSOS(circleId: String, message: String, recipientIds: [String]) async throws -> SOSSendResponse {
        let body: [String: Any] = [
            "circleId": circleId,
            "message": message,
            "recipientIds": recipientIds,
        ]
        return try await postMutation("sos.send", body: body)
    }

    func getRecentSOS(circleId: String? = nil, limit: Int = 20) async throws -> [SOSItem] {
        var input: [String: Any] = ["limit": limit]
        if let circleId { input["circleId"] = circleId }
        return try await getQuery("sos.getRecent", input: input)
    }

    func submitHeatmapData(circleId: String, weekData: [[String: Any]]) async throws {
        let body: [String: Any] = ["circleId": circleId, "weekData": weekData]
        let _: [String: Bool] = try await postMutation("circles.submitHeatmapData", body: body)
    }

    func generateShareLink(circleId: String) async throws -> ShareLinkResponse {
        let body: [String: Any] = ["circleId": circleId]
        return try await postMutation("invite.generateShareLink", body: body)
    }

    func getSundaySummary(circleId: String) async throws -> SundaySummaryResponse {
        let input: [String: Any] = ["circleId": circleId]
        return try await getQuery("circles.getSundaySummary", input: input)
    }

    func getCircleHeatmap(circleId: String, weeksBack: Int = 12) async throws -> CircleHeatmapResponse {
        let input: [String: Any] = ["circleId": circleId, "weeksBack": weeksBack]
        return try await getQuery("circles.getCircleHeatmap", input: input)
    }

    func setSOSContacts(circleId: String, contactUserIds: [String]) async throws -> SOSContactsResponse {
        let body: [String: Any] = ["circleId": circleId, "contactUserIds": contactUserIds]
        return try await postMutation("sos.setSOSContacts", body: body)
    }

    func registerPushToken(_ token: String) async {
        guard let userId else { return }
        let body: [String: Any] = ["userId": userId, "pushToken": token]
        do {
            let _: [String: Bool] = try await postMutation("auth.registerPushToken", body: body)
        } catch {
        }
    }

    func shareGratitude(circleIds: [String], gratitudeText: String, isAnonymous: Bool, displayName: String?) async throws -> ShareGratitudeResponse {
        var body: [String: Any] = [
            "circleIds": circleIds,
            "gratitudeText": gratitudeText,
            "isAnonymous": isAnonymous,
        ]
        if let displayName {
            body["displayName"] = displayName
        }
        return try await postMutation("gratitudes.share", body: body)
    }

    func getGratitudeWall(circleId: String, weeksBack: Int = 0) async throws -> GratitudeWallResponse {
        let input: [String: Any] = ["circleId": circleId, "weeksBack": weeksBack]
        return try await getQuery("gratitudes.getWall", input: input)
    }

    func deleteGratitude(circleId: String, gratitudeId: String) async throws {
        let body: [String: Any] = ["circleId": circleId, "gratitudeId": gratitudeId]
        let _: [String: Bool] = try await postMutation("gratitudes.delete", body: body)
    }

    func getGratitudeNewCount(circleId: String) async throws -> GratitudeNewCountResponse {
        let input: [String: Any] = ["circleId": circleId]
        return try await getQuery("gratitudes.getNewCount", input: input)
    }

    func markGratitudesSeen(circleId: String) async throws {
        let body: [String: Any] = ["circleId": circleId]
        let _: [String: Bool] = try await postMutation("gratitudes.markSeen", body: body)
    }

    func getGratitudeWeekCount(circleId: String) async throws -> GratitudeWeekCountResponse {
        let input: [String: Any] = ["circleId": circleId]
        return try await getQuery("gratitudes.getWeekCount", input: input)
    }

    private func getQuery<T: Decodable & Sendable>(_ procedure: String, input: [String: Any]? = nil) async throws -> T {
        var urlString = "\(baseURL)/api/trpc/\(procedure)"

        if let input {
            let jsonData = try JSONSerialization.data(withJSONObject: input)
            let inputString = String(data: jsonData, encoding: .utf8) ?? "{}"
            let encoded = inputString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlString += "?input=\(encoded)"
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeaders(&request)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }

        let decoded = try decoder.decode(APIResponse<T>.self, from: data)
        return decoded.result.data
    }

    private func postMutation<T: Decodable & Sendable>(_ procedure: String, body: [String: Any?]) async throws -> T {
        guard let url = URL(string: "\(baseURL)/api/trpc/\(procedure)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(&request)

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }

        let decoded = try decoder.decode(APIResponse<T>.self, from: data)
        return decoded.result.data
    }

    private func addAuthHeaders(_ request: inout URLRequest) {
        if let userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
    }
}

nonisolated enum APIError: Error, LocalizedError, Sendable {
    case invalidURL
    case serverError
    case unauthorized
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request URL"
        case .serverError: return "Server error. Please try again."
        case .unauthorized: return "Please sign in to continue"
        case .decodingError: return "Unexpected response format"
        }
    }
}
