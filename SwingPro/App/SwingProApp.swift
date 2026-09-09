import SwiftUI

@main
struct SwingProApp: App {
    @StateObject private var appState = AppState()
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack(path: $appState.path) {
            ModeSelectionView()
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .practice:
            PracticeModeView(appState: appState)
        case .field:
            FieldModeView(appState: appState)
        case .feed:
            AnalysisFeedView()
        case .clipDetail(let clipId):
            ClipDetailView(clipId: clipId)
        case .settings:
            SettingsView(appState: appState)
        }
    }
}
