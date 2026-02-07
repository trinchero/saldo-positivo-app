import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("profile_first_name") private var profileFirstName: String = "Andrea"
    @AppStorage("profile_last_name") private var profileLastName: String = "Trinchero"
    @AppStorage("profile_email") private var profileEmail: String = "andrea_trinchero@icloud.com"
    @AppStorage("profile_image_data") private var profileImageData: Data = Data()

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isSaving = false

    private let horizontalInset: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let image = avatarImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40, weight: .semibold))
                                                .foregroundColor(.secondary)
                                        )
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(.separator), lineWidth: 1)
                            )

                            Circle()
                                .fill(Color.green)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.footnote.weight(.bold))
                                        .foregroundColor(.black)
                                )
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 14) {
                        profileField(title: "First Name", text: $firstName)
                        profileField(title: "Last Name", text: $lastName)
                        profileField(title: "Email", text: $email, keyboard: .emailAddress)
                    }

                    Button {
                        saveProfile()
                    } label: {
                        Text("Save")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isSaving)
                    .padding(.top, 4)
                }
                .padding(.horizontal, horizontalInset)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(Color(.systemBackground))
        .onAppear {
            firstName = profileFirstName
            lastName = profileLastName
            email = profileEmail
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    profileImageData = data
                }
            }
        }
    }

    private func profileField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            TextField(title, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func saveProfile() {
        isSaving = true
        profileFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        profileLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        profileEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        isSaving = false
        dismiss()
    }

    private var avatarImage: UIImage? {
        guard !profileImageData.isEmpty else { return nil }
        return UIImage(data: profileImageData)
    }

    private var header: some View {
        ZStack {
            Text("Profile")
                .font(.headline.weight(.semibold))

            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }

                Spacer()
            }
        }
        .padding(.horizontal, horizontalInset)
        .frame(height: 64)
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
}
