import SwiftUI

/// Container for the Tracking tab with segmented control: Sleep | Food | Diapers
struct TrackingView: View {
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Sección", selection: $selectedSegment) {
                    Text("Sueño").tag(0)
                    Text("Comida").tag(1)
                    Text("Pañales").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedSegment {
                case 0:
                    SleepView()
                case 1:
                    FeedingView()
                case 2:
                    DiaperView()
                default:
                    SleepView()
                }
            }
            .navigationTitle("Registro")
        }
    }
}
