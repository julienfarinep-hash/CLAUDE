import SwiftUI

struct ContentView: View {
    @StateObject private var checker = PageChecker()
    @State private var urlString: String = "https://animating-country-ahead.ngrok-free.dev"

    var body: some View {
        NavigationStack {
            Form {
                Section("Page à vérifier") {
                    TextField("https://exemple.com", text: $urlString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Résultat") {
                    ResultView(result: checker.result, lastCheckedAt: checker.lastCheckedAt)
                }
            }
            .navigationTitle("Web Page Checker")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        Task { await checker.check(urlString: urlString) }
                    } label: {
                        if checker.result == .checking {
                            ProgressView()
                        } else {
                            Label("Rafraîchir", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(checker.result == .checking || urlString.isEmpty)
                }
            }
        }
    }
}

private struct ResultView: View {
    let result: CheckResult
    let lastCheckedAt: Date?

    var body: some View {
        switch result {
        case .idle:
            Text("Appuie sur Rafraîchir pour vérifier la page.")
                .foregroundStyle(.secondary)
        case .checking:
            Label("Vérification en cours…", systemImage: "ellipsis.circle")
                .foregroundStyle(.secondary)
        case .success(let statusCode, let durationMs):
            VStack(alignment: .leading, spacing: 8) {
                Label("HTTP \(statusCode) — \(statusText(for: statusCode))", systemImage: statusCode < 400 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(statusCode < 400 ? .green : .red)
                Text("Temps de réponse : \(durationMs) ms")
                    .foregroundStyle(.secondary)
                if let lastCheckedAt {
                    Text("Dernière vérification : \(lastCheckedAt.formatted(date: .omitted, time: .standard))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        case .failure(let message):
            VStack(alignment: .leading, spacing: 8) {
                Label("Échec : \(message)", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                if let lastCheckedAt {
                    Text("Dernière tentative : \(lastCheckedAt.formatted(date: .omitted, time: .standard))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func statusText(for code: Int) -> String {
        switch code {
        case 200..<300: return "OK"
        case 300..<400: return "Redirection"
        case 400..<500: return "Erreur client"
        case 500..<600: return "Erreur serveur"
        default: return "Inconnu"
        }
    }
}

#Preview {
    ContentView()
}
