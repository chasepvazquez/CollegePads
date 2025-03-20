//
//  ChatsListView.swift
//  CollegePads
//
//  Updated to include pull-to-refresh (iOS 15+), loading indicators, and improved empty state handling.
//  This ensures that users can manually refresh their chats and receive clear feedback while data loads.

import SwiftUI

struct ChatsListView: View {
    @StateObject private var viewModel = ChatsListViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading chats...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.chats.isEmpty {
                    Text("No chats yet.")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.chats) { chat in
                        NavigationLink(destination: ChatView(viewModel: ChatViewModel(chatID: chat.id))) {
                            VStack(alignment: .leading) {
                                Text("Chat with: \(chat.participants.filter { $0 != viewModel.currentUserID ?? "" }.joined(separator: ", "))")
                                    .font(.headline)
                                Text("Started on: \(chat.createdAt, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    // Pull-to-refresh support (iOS 15+)
                    .refreshable {
                        viewModel.fetchChats()
                    }
                }
            }
            .navigationTitle("My Chats")
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
