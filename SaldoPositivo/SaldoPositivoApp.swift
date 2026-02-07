import SwiftUI
import Foundation

@main
struct SaldoPositivoApp: App {
    init() {
        // On app launch, ensure settings are synced to the shared UserDefaults
        Self.syncSettingsToSharedDefaults()
        let container = AppRepositoryContainer.mock()
        _sessionViewModel = StateObject(wrappedValue: AppSessionViewModel(repositories: container))
        _walletContextViewModel = StateObject(wrappedValue: WalletContextViewModel(repositories: container))
    }
    
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var sessionViewModel: AppSessionViewModel
    @StateObject private var walletContextViewModel: WalletContextViewModel
    
    var body: some Scene {
        WindowGroup {
            Group {
                if sessionViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
                // Use the optional SwiftData container that won't affect existing code
                .withSwiftData()
                // Perform the migration silently on app startup
                .task {
                    await SwiftDataProvider.shared.startMigration()
                }
                .task {
                    await sessionViewModel.bootstrap()
                }
                .task(id: sessionViewModel.session?.user.id) {
                    if let userID = sessionViewModel.session?.user.id {
                        await walletContextViewModel.bootstrap(for: userID)
                    } else {
                        walletContextViewModel.clear()
                    }
                }
                .environmentObject(settingsViewModel)
                .environmentObject(sessionViewModel)
                .environmentObject(walletContextViewModel)
                .preferredColorScheme(settingsViewModel.selectedTheme.colorScheme)
                .environment(\.locale, Locale(identifier: settingsViewModel.selectedLanguage.localeIdentifier))
        }
    }
    
    // This function ensures that all settings needed by widgets are available in shared UserDefaults
    private static func syncSettingsToSharedDefaults() {
        let sharedDefaults = UserDefaults(suiteName: StorageService.appGroupID)
        
        // Sync currency setting
        if let currency = UserDefaults.standard.string(forKey: "selectedCurrency") {
            sharedDefaults?.set(currency, forKey: "selectedCurrency")
            sharedDefaults?.synchronize()
        } else {
            // If no currency in standard defaults, set a default in both places
            let defaultCurrency = "EUR"
            UserDefaults.standard.set(defaultCurrency, forKey: "selectedCurrency")
            sharedDefaults?.set(defaultCurrency, forKey: "selectedCurrency")
            sharedDefaults?.synchronize()
        }
    }
}
