import Foundation

/// Where the app finds the server. The value comes from LIGHTEN_BASE_URL in
/// Config/Debug.xcconfig or Config/Release.xcconfig, through Info.plist.
///
/// It is the student cabinet's address, not the API's: like the site, the app
/// calls `<cabinet>/api/...`, and the cabinet forwards it to the API.
enum AppConfig {
    static let baseURL: URL = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "LightenBaseURL") as? String ?? ""
        guard let url = URL(string: raw), url.scheme != nil else {
            fatalError("LightenBaseURL is missing in Info.plist: set LIGHTEN_BASE_URL in Config/*.xcconfig")
        }
        return url
    }()

    /// `/api/...` on the cabinet's origin.
    static func apiURL(_ path: String) -> URL {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.appendingPathComponent("api").appendingPathComponent(trimmed)
    }

    /// A file uploaded by the teacher, such as a slide (`fileUrl` in packages/shared).
    static func fileURL(_ fileId: String) -> URL {
        apiURL("files/\(fileId)")
    }
}
