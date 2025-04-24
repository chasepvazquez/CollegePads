import SwiftUI
import FirebaseAuth

struct PasswordResetView: View {
  @EnvironmentObject var authViewModel: AuthViewModel
  @Environment(\.presentationMode) var presentationMode

  @State private var email: String = ""
  @State private var error: String?
  @State private var successMessage: String?
  @State private var isLoading = false

  private var isEmailValid: Bool {
    let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.contains("@") && trimmed.contains(".")
  }

  let onDismiss: () -> Void

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Reset Password")
          .font(AppTheme.titleFont)

        TextField("Enter your email", text: $email)
          .autocapitalization(.none)
          .disableAutocorrection(true)
          .keyboardType(.emailAddress)
          .padding(AppTheme.defaultPadding)
          .background(AppTheme.cardBackground)
          .cornerRadius(AppTheme.defaultCornerRadius)
          .accessibilityLabel("Email for password reset")

        if let error = error {
          Text(error)
            .font(AppTheme.bodyFont)
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
        }

        if let msg = successMessage {
          Text(msg)
            .font(AppTheme.bodyFont)
            .foregroundColor(.green)
            .multilineTextAlignment(.center)
        }

        Button {
          sendReset()
        } label: {
          if isLoading {
            ProgressView()
          } else {
            Text("Send Reset Link")
              .frame(maxWidth: .infinity)
              .padding(AppTheme.defaultPadding)
              .background(isEmailValid ? AppTheme.primaryColor : AppTheme.primaryColor.opacity(0.5))
              .foregroundColor(.white)
              .cornerRadius(AppTheme.defaultCornerRadius)
          }
        }
        .disabled(!isEmailValid || isLoading)

        Spacer()
      }
      .padding()
      .navigationBarItems(leading:
        Button("Close") {
          onDismiss()
        }
      )
    }
  }

  private func sendReset() {
    error = nil
    successMessage = nil
    isLoading = true
    let addr = email.trimmingCharacters(in: .whitespacesAndNewlines)
    Auth.auth().sendPasswordReset(withEmail: addr) { err in
      DispatchQueue.main.async {
        isLoading = false
        if let e = err {
          error = e.localizedDescription
        } else {
          successMessage = "Check \(addr) for reset instructions."
          // auto-dismiss after a short delay
          DispatchQueue.main.asyncAfter(deadline: .now()+2) {
            onDismiss()
          }
        }
      }
    }
  }
}
