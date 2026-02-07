import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    private let horizontalInset: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 20) {
                Image("SaldoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)

                Text("SaldoPositivo")
                    .font(.title2.weight(.semibold))

                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 28)
        }
        .navigationBarBackButtonHidden(true)
        .background(Color(.systemBackground))
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
