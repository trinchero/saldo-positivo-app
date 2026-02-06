import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var opacity: Double = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    Button("Preview") {}
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .buttonStyle(PressableButtonStyle())
}
