import SwiftUI

struct ChatsListView: View {
    @StateObject private var viewModel = ChatsListViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading chats...")
                            .font(AppTheme.bodyFont)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.chats.isEmpty {
                        Text("No chats yet.")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.secondaryColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(viewModel.chats) { chat in
                            NavigationLink(destination: ChatView(viewModel: ChatViewModel(chatID: chat.id))) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Chat with: \(chat.participants.filter { $0 != viewModel.currentUserID ?? "" }.joined(separator: ", "))")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(.primary)
                                    Text("Started on: \(chat.createdAt, formatter: dateFormatter)")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.secondaryColor)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            viewModel.fetchChats()
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("My Chats")
                            .font(AppTheme.titleFont)
                            .foregroundColor(.primary)
                    }
                }
                .onAppear {
                    viewModel.fetchChats()
                }
                .alert(item: Binding(
                    get: {
                        if let errorMessage = viewModel.errorMessage {
                            return GenericAlertError(message: errorMessage)
                        }
                        return nil
                    },
                    set: { _ in viewModel.errorMessage = nil }
                )) { alertError in
                    Alert(title: Text("Error"),
                          message: Text(alertError.message),
                          dismissButton: .default(Text("OK")))
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

struct ChatsListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsListView()
    }
}
