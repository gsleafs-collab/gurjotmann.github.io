import Foundation
import Security

/// Data shared between the app and the widget extension through the App Group.
enum SharedStore {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: AppConfig.appGroup) ?? .standard
    }

    static var readings: [GlucoseReading] {
        get { decode([GlucoseReading].self, key: "readings") ?? [] }
        set { encode(newValue, key: "readings") }
    }

    static var settings: AppSettings {
        get { decode(AppSettings.self, key: "settings") ?? AppSettings() }
        set { encode(newValue, key: "settings") }
    }

    static var sessionID: String? {
        get { defaults.string(forKey: "dexcomSessionID") }
        set { defaults.set(newValue, forKey: "dexcomSessionID") }
    }

    private static func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func encode<T: Encodable>(_ value: T, key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}

/// Keeps the Dexcom login in the Keychain, shared with the widget so it can refresh on its own.
enum CredentialStore {
    private static let service = "GlucoseGlance.Dexcom"
    private static let account = "share"

    static func load() -> DexcomCredentials? {
        for useGroup in [true, false] {
            var query = baseQuery(useGroup: useGroup)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            var result: AnyObject?
            if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
               let data = result as? Data,
               let credentials = try? JSONDecoder().decode(DexcomCredentials.self, from: data) {
                return credentials
            }
        }
        return nil
    }

    static func save(_ credentials: DexcomCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        delete()
        var status = add(data, useGroup: true)
        if status == errSecMissingEntitlement {
            // Shared keychain group not set up (e.g. signing issue). Fall back so the app still works.
            status = add(data, useGroup: false)
        }
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    static func delete() {
        SecItemDelete(baseQuery(useGroup: true) as CFDictionary)
        SecItemDelete(baseQuery(useGroup: false) as CFDictionary)
    }

    private static func add(_ data: Data, useGroup: Bool) -> OSStatus {
        var query = baseQuery(useGroup: useGroup)
        query[kSecValueData as String] = data
        // Readable after first unlock so lock screen widgets can refresh while the phone is locked.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(query as CFDictionary, nil)
    }

    private static func baseQuery(useGroup: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if useGroup, let group = AppConfig.keychainAccessGroup, !group.hasPrefix("$") {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }
}

enum GlucoseFetcher {
    /// Pulls the last 24 hours from Dexcom and caches it for the app and widgets.
    static func fetchAndCache() async throws -> [GlucoseReading] {
        guard let credentials = CredentialStore.load() else { throw DexcomError.notSignedIn }
        let readings = try await DexcomShareClient(credentials: credentials).latestReadings()
        SharedStore.readings = readings
        return readings
    }
}
