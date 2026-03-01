import SwiftUI

struct AIChatView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AIChatViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick Actions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        AIQuickAction(title: "Plan semanal", icon: "calendar") {
                            Task { await viewModel.generateMealPlan() }
                        }
                        AIQuickAction(title: "Resumen", icon: "doc.text") {
                            Task { await viewModel.generateWeeklySummary() }
                        }
                        AIQuickAction(title: "Tips desarrollo", icon: "figure.child") {
                            Task { await viewModel.generateDevelopmentTips() }
                        }
                        AIQuickAction(title: "Lista mercado", icon: "cart") {
                            Task { await viewModel.generateGroceryList() }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                Divider()

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .padding()
                                    Text("Pensando...")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let last = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input
                HStack(spacing: 12) {
                    TextField("Pregunta sobre tu bebé...", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.send)
                        .onSubmit {
                            Task { await viewModel.sendMessage() }
                        }

                    Button {
                        Task { await viewModel.sendMessage() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.pink)
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("Asistente IA")
            .onAppear {
                viewModel.babyId = appState.currentBaby?.id
            }
        }
    }
}

// MARK: - Quick Action

struct AIQuickAction: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.pink.opacity(0.1))
            .foregroundStyle(.pink)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessageUI

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(message.isUser ? Color.pink : Color(.systemGray5))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(DateFormatters.time.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser { Spacer() }
        }
    }
}
