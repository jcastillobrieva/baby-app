import SwiftUI

/// Large button used for starting/stopping timers (sleep, breastfeeding).
struct TimerButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

/// Extra-large button for Night Mode (60pt+ touch target).
struct NightModeButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(color.opacity(0.3))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
