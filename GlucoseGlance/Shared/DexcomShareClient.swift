import Foundation

/// Dexcom Share servers. Canadian accounts use the "outside US" server.
enum DexcomRegion: String, Codable, Hashable, CaseIterable, Identifiable {
    case us
    case outsideUS
    case japan

    var id: String { rawValue }

    var label: String {
        switch self {
        case .us: return "United States"
        case .outsideUS: return "Outside US (incl. Canada)"
        case .japan: return "Japan"
        }
    }

    var baseURL: String {
        switch self {
        case .us: return "https://share2.dexcom.com/ShareWebServices/Services"
        case .outsideUS: return "https://shareous1.dexcom.com/ShareWebServices/Services"
        case .japan: return "https://share.dexcom.jp/ShareWebServices/Services"
        }
    }

    var applicationID: String {
        switch self {
        case .us, .outsideUS: return "d89443d2-327c-4a6f-89e5-496bbb0317db"
        case .japan: return "d8665ade-9673-4e27-9ff6-92db4ce13d13"
        }
    }
}

struct DexcomCredentials: Codable, Equatable {
    var username: String
    var password: String
    var region: DexcomRegion
}

enum DexcomError: LocalizedError {
    case notSignedIn
    case invalidCredentials
    case tooManyAttempts
    case sessionExpired
    case server(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Sign in to your Dexcom account to see readings."
        case .invalidCredentials: return "Dexcom didn't accept that username or password. Check the region too."
        case .tooManyAttempts: return "Too many sign-in attempts. Dexcom has locked the account for a few minutes."
        case .sessionExpired: return "The Dexcom session expired."
        case .server(let message): return "Dexcom error: \(message)"
        case .badResponse: return "Couldn't read the response from Dexcom."
        }
    }
}

/// Talks to the Dexcom Share service, the same source Sugarmate, Nightscout and pydexcom use.
/// This is not an official public API, so Dexcom could change it without notice.
final class DexcomShareClient {
    private static let nullID = "00000000-0000-0000-0000-000000000000"

    let credentials: DexcomCredentials
    private let session: URLSession

    init(credentials: DexcomCredentials, session: URLSession = .shared) {
        self.credentials = credentials
        self.session = session
    }

    /// Returns readings newest first. Reuses the cached session and signs in again only when needed.
    func latestReadings(minutes: Int = 1440, maxCount: Int = 288) async throws -> [GlucoseReading] {
        if let cached = SharedStore.sessionID {
            do {
                return try await readings(sessionID: cached, minutes: minutes, maxCount: maxCount)
            } catch DexcomError.sessionExpired {
                SharedStore.sessionID = nil
            }
        }
        let sessionID = try await login()
        SharedStore.sessionID = sessionID
        return try await readings(sessionID: sessionID, minutes: minutes, maxCount: maxCount)
    }

    func login() async throws -> String {
        let region = credentials.region
        let accountID = try await postForID("General/AuthenticatePublisherAccount", body: [
            "accountName": credentials.username,
            "password": credentials.password,
            "applicationId": region.applicationID,
        ])
        let sessionID = try await postForID("General/LoginPublisherAccountById", body: [
            "accountId": accountID,
            "password": credentials.password,
            "applicationId": region.applicationID,
        ])
        return sessionID
    }

    private func readings(sessionID: String, minutes: Int, maxCount: Int) async throws -> [GlucoseReading] {
        var components = URLComponents(string: "\(credentials.region.baseURL)/Publisher/ReadPublisherLatestGlucoseValues")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionID),
            URLQueryItem(name: "minutes", value: String(minutes)),
            URLQueryItem(name: "maxCount", value: String(maxCount)),
        ]
        let data = try await post(components.url!, body: [:])
        guard let entries = try? JSONDecoder().decode([ShareEntry].self, from: data) else {
            throw DexcomError.badResponse
        }
        return entries.compactMap(\.reading).sorted { $0.date > $1.date }
    }

    private func postForID(_ path: String, body: [String: String]) async throws -> String {
        let data = try await post(URL(string: "\(credentials.region.baseURL)/\(path)")!, body: body)
        let id = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"").union(.whitespacesAndNewlines))
        guard !id.isEmpty, id != Self.nullID else { throw DexcomError.invalidCredentials }
        return id
    }

    private func post(_ url: URL, body: [String: String]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Dexcom Share/3.0.2.11", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw DexcomError.badResponse }
        guard (200..<300).contains(http.statusCode) else { throw Self.error(from: data) }
        return data
    }

    private static func error(from data: Data) -> DexcomError {
        struct ShareError: Decodable {
            let Code: String?
            let Message: String?
        }
        guard let shareError = try? JSONDecoder().decode(ShareError.self, from: data),
              let code = shareError.Code else { return .badResponse }
        switch code {
        case "SessionIdNotFound", "SessionNotValid":
            return .sessionExpired
        case "AccountPasswordInvalid", "SSO_AuthenticatePasswordInvalid", "SSO_AuthenticateAccountNotFound":
            return .invalidCredentials
        case "SSO_AuthenticateMaxAttemptsExceeed", "SSO_AuthenticateMaxAttemptsExceeded":
            return .tooManyAttempts
        default:
            return .server(shareError.Message ?? code)
        }
    }
}

/// Raw Share entry, e.g. {"WT":"Date(1691455258000)","Value":120,"Trend":"Flat"}
private struct ShareEntry: Decodable {
    let wt: String
    let value: Double
    let trend: Trend?

    enum CodingKeys: String, CodingKey {
        case wt = "WT"
        case value = "Value"
        case trend = "Trend"
    }

    enum Trend: Decodable {
        case name(String)
        case index(Int)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let index = try? container.decode(Int.self) {
                self = .index(index)
            } else {
                self = .name(try container.decode(String.self))
            }
        }

        var glucoseTrend: GlucoseTrend {
            switch self {
            case .name(let name): return GlucoseTrend(shareName: name)
            case .index(let index): return GlucoseTrend(shareIndex: index)
            }
        }
    }

    var reading: GlucoseReading? {
        let digits = wt.drop { !$0.isNumber }.prefix { $0.isNumber }
        guard let milliseconds = Double(digits) else { return nil }
        return GlucoseReading(
            date: Date(timeIntervalSince1970: milliseconds / 1000),
            mgdl: Int(value.rounded()),
            trend: trend?.glucoseTrend ?? .unknown
        )
    }
}
