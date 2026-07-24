import Foundation

enum CheckResult: Equatable {
    case idle
    case checking
    case success(statusCode: Int, durationMs: Int)
    case failure(message: String)
}

@MainActor
final class PageChecker: ObservableObject {
    @Published var result: CheckResult = .idle
    @Published var lastCheckedAt: Date?

    func check(urlString: String) async {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = Self.normalizedURL(from: trimmed) else {
            result = .failure(message: "URL invalide")
            return
        }

        result = .checking
        let start = Date()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let durationMs = Int(Date().timeIntervalSince(start) * 1000)
            guard let httpResponse = response as? HTTPURLResponse else {
                result = .failure(message: "Réponse inattendue")
                return
            }
            result = .success(statusCode: httpResponse.statusCode, durationMs: durationMs)
        } catch {
            result = .failure(message: error.localizedDescription)
        }

        lastCheckedAt = Date()
    }

    private static func normalizedURL(from string: String) -> URL? {
        guard !string.isEmpty else { return nil }
        let candidate = string.contains("://") ? string : "https://\(string)"
        guard let url = URL(string: candidate), url.host != nil else { return nil }
        return url
    }
}
