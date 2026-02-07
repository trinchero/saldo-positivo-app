import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)

            Image("SaldoLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            Text("SaldoPositivo")
                .font(.title2.weight(.semibold))

            Text("Coming soon")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
}
