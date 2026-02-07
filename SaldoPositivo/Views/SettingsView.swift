import SwiftUI
import UniformTypeIdentifiers
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsViewModel
    @Environment(\.modelContext) private var modelContext

    @AppStorage("profile_name") private var profileName: String = "Andrea"
    @AppStorage("profile_email") private var profileEmail: String = "andrea_trinchero@icloud.com"
    @AppStorage("notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("faceid_enabled") private var faceIDEnabled: Bool = false

    @State private var showingImportFilePicker = false
    @State private var showingExportShareSheet = false
    @State private var exportURL: URL? = nil
    @State private var showingResetConfirmation = false
    @State private var showingImportSuccess = false
    @State private var showingImportFailure = false
    @State private var showingExportSuccess = false
    @State private var versionTapCount = 0
    @State private var showAuthorPopup = false
    @State private var showAuthorLink = false
    @State private var showProfileEditor = false
    @State private var showQRCode = false
    @State private var showResetPasswordInfo = false
    @State private var showLogoutInfo = false

    var body: some View {
        NavigationView {
            Form {
                accountSection
                preferencesSection
                appearanceSection
                dataManagementSection
                feedbackSection
                aboutSection
                logoutSection
            }
            .sheet(isPresented: $showingImportFilePicker) {
                documentPicker
            }
            .sheet(isPresented: $showingExportShareSheet) {
                shareSheet
            }
            .sheet(isPresented: $showProfileEditor) {
                ProfileEditorView(name: $profileName, email: $profileEmail)
            }
            .sheet(isPresented: $showQRCode) {
                QRCodeSheetView(payload: profileEmail)
            }
            .alert("Data Reset", isPresented: $showingResetConfirmation) {
                resetAlertButtons
            } message: {
                Text("This will delete all your expenses and budgets. This action cannot be undone.")
            }
            .alert("Import Successful", isPresented: $showingImportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your data has been imported successfully.")
            }
            .alert("Import Failed", isPresented: $showingImportFailure) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Failed to import data. Please check the file format and try again.")
            }
            .alert("Export Successful", isPresented: $showingExportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your data has been exported successfully.")
            }
            .alert("Author", isPresented: $showAuthorPopup) {
                Button("Cancel", role: .cancel) { }
                Button("Open") { showAuthorLink = true }
            } message: {
                Text("Open the author website?")
            }
            .alert("Reset Password", isPresented: $showResetPasswordInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Password reset will be available after backend authentication is enabled.")
            }
            .alert("Logout", isPresented: $showLogoutInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Logout will be enabled when authentication is active.")
            }
        }
        .onChange(of: showAuthorLink) { _, newValue in
            if newValue, let url = URL(string: "https://www.trincheroandrea.com") {
                UIApplication.shared.open(url)
                showAuthorLink = false
            }
        }
    }

    private var accountSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profileName)
                        .font(.headline)
                    Text(profileEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Edit") {
                    showProfileEditor = true
                }
                .buttonStyle(.borderless)
                .font(.subheadline.weight(.semibold))
            }

            Button(action: {
                showQRCode = true
            }) {
                HStack {
                    Spacer()
                    Label("Scan Code", systemImage: "qrcode.viewfinder")
                    Spacer()
                }
            }
        }
    }

    private var preferencesSection: some View {
        Section(header: Text("Preferences")) {
            Toggle(isOn: $notificationsEnabled) {
                Label("Notifications", systemImage: "bell.badge")
            }

            NavigationLink {
                securityView
            } label: {
                Label("Security", systemImage: "lock.shield")
            }
        }
    }

    private var securityView: some View {
        Form {
            Section(header: Text("Security")) {
                Toggle("Use Face ID", isOn: $faceIDEnabled)

                Button("Reset Password") {
                    showResetPasswordInfo = true
                }
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            themePicker
            languagePicker
            currencyPicker
            categoryPicker

            NavigationLink {
                CategoriesSettingsView()
            } label: {
                Text("Manage Categories")
            }
        }
    }

    private var feedbackSection: some View {
        Section(header: Text("Feedback")) {
            Button(action: requestReview) {
                Label("Rate SaldoPositivo", systemImage: "star.bubble")
            }

            Link(destination: URL(string: "mailto:andrea_trinchero@icloud.com?subject=SaldoPositivo%20Feedback")!) {
                Label("Contact Us", systemImage: "envelope")
            }
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutInfo = true
            } label: {
                HStack {
                    Spacer()
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
    }

    private var themePicker: some View {
        Picker("Theme", selection: $settingsManager.selectedTheme) {
            ForEach(AppTheme.allCases) { theme in
                Text(theme.displayName).tag(theme)
            }
        }
        .pickerStyle(.menu)
    }

    private var currencyPicker: some View {
        Picker("Currency", selection: $settingsManager.selectedCurrency) {
            ForEach(availableCurrencies, id: \.code) { currency in
                currencyRow(for: currency)
            }
        }
        .pickerStyle(.menu)
    }

    private func currencyRow(for currency: (code: String, symbol: String, name: String)) -> some View {
        let localizedName = NSLocalizedString(currency.name, comment: "Currency name")
        return Text("\(currency.symbol) \(localizedName) (\(currency.code))")
            .tag(currency.code)
    }

    private var languagePicker: some View {
        Picker("Language", selection: $settingsManager.selectedLanguage) {
            ForEach(AppLanguage.allCases) { language in
                Text(language.displayName).tag(language)
            }
        }
        .pickerStyle(.menu)
    }

    private var categoryPicker: some View {
        Picker("Default Category", selection: $settingsManager.defaultCategory) {
            ForEach(Category.allCases, id: \.self) { category in
                categoryRow(for: category)
            }
        }
        .pickerStyle(.menu)
    }

    private func categoryRow(for category: Category) -> some View {
        HStack {
            Circle()
                .fill(category.color)
                .frame(width: 12, height: 12)
            Text(category.displayName).tag(category)
        }
    }

    private var dataManagementSection: some View {
        Section(header: Text("Data Management")) {
            exportButton
            importButton
            resetButton
        }
    }

    private var exportButton: some View {
        Button(action: {
            exportData()
        }) {
            Label("Export Data", systemImage: "square.and.arrow.up")
        }
    }

    private var importButton: some View {
        Button(action: {
            showingImportFilePicker = true
        }) {
            Label("Import Data", systemImage: "square.and.arrow.down")
        }
    }

    private var resetButton: some View {
        Button(role: .destructive, action: {
            showingResetConfirmation = true
        }) {
            Label("Reset All Data", systemImage: "trash")
        }
        .foregroundColor(.red)
    }

    private var aboutSection: some View {
        Section(header: Text("About")) {
            versionRow
            websiteRow
            copyrightRow
        }
    }

    private var versionRow: some View {
        Button(action: {
            versionTapCount += 1
            if versionTapCount >= 10 {
                versionTapCount = 0
                showAuthorPopup = true
            }
        }) {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var websiteRow: some View {
        Link(destination: URL(string: "https://www.saldopositivo.net")!) {
            HStack {
                Text("Website")
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var copyrightRow: some View {
        let year = Calendar.current.component(.year, from: Date())
        let yearText = String(format: "%d", year)
        return HStack {
            Spacer()
            Text("© \(yearText) SaldoPositivo · All rights reserved")
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var documentPicker: some View {
        DocumentPicker(
            types: [UTType.json],
            allowsMultipleSelection: false
        ) { urls in
            guard let url = urls.first else { return }
            let success = settingsManager.importData(from: url)
            if success {
                showingImportSuccess = true
            } else {
                showingImportFailure = true
            }
        }
    }

    private var shareSheet: some View {
        Group {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private var resetAlertButtons: some View {
        Group {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settingsManager.resetAllData(using: modelContext)
            }
        }
    }

    private func exportData() {
        if let url = settingsManager.exportData() {
            exportURL = url
            showingExportShareSheet = true
            showingExportSuccess = true
        }
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

private struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var email: String

    @State private var tempName: String = ""
    @State private var tempEmail: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $tempName)
                TextField("Email", text: $tempEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        name = tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? name : tempName
                        email = tempEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? email : tempEmail
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            tempName = name
            tempEmail = email
        }
    }
}

private struct QRCodeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let payload: String

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(uiImage: makeQRCode(from: payload))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Share this code to connect with your wallet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("My Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func makeQRCode(from string: String) -> UIImage {
        let data = Data(string.utf8)
        guard
            let filter = CIFilter(name: "CIQRCodeGenerator"),
            let colorFilter = CIFilter(name: "CIFalseColor")
        else {
            return UIImage(systemName: "qrcode") ?? UIImage()
        }
        let context = CIContext(options: nil)

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        colorFilter.setValue(filter.outputImage, forKey: kCIInputImageKey)
        colorFilter.setValue(CIColor(color: UIColor.label), forKey: "inputColor0")
        colorFilter.setValue(CIColor(color: UIColor.systemBackground), forKey: "inputColor1")

        guard
            let outputImage = colorFilter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
            let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            return UIImage(systemName: "qrcode") ?? UIImage()
        }

        return UIImage(cgImage: cgImage)
    }
}

// Document Picker for importing files
struct DocumentPicker: UIViewControllerRepresentable {
    let types: [UTType]
    let allowsMultipleSelection: Bool
    let onPick: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls)
        }
    }
}

// ShareSheet for exporting files
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
}
