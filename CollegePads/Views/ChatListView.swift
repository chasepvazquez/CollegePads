//
//  ChatsListView.swift
//  CollegePads
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

struct ChatsListView: View {
    @StateObject private var viewModel = ChatsListViewModel()
    
    var body: some View {
        NavigationView {
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
