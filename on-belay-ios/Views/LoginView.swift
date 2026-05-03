import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var firebase = FirebaseService.shared

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.climbing")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding()

            Text(NSLocalizedString("app_name", comment: ""))
                .font(.largeTitle)
                .bold()

            Spacer()

            // Note: Implementation of Google and Apple sign in requires
            // specific setup in Xcode and Info.plist (URL schemes, etc.)
            // Here we provide the logic flow using Firebase.

            Button(action: signInWithGoogle) {
                HStack {
                    Image(systemName: "g.circle.fill")
                    Text(NSLocalizedString("sign_in_google", comment: ""))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    handleAppleSignIn(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal)
        }
        .padding()
    }

    func signInWithGoogle() {
        // In a real app, you'd use GoogleSignIn SDK to get an ID token
        // and then:
        // let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        // Auth.auth().signIn(with: credential)
        print("Google Sign In clicked")
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                guard let appleIDToken = appleIDCredential.identityToken else { return }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }
                let nonce = LoginView.randomNonceString()
                let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                               rawNonce: nonce,
                                                               fullName: nil)

                Auth.auth().signIn(with: credential) { _, error in
                    if let error = error {
                        print("Error signing in with Apple: \(error.localizedDescription)")
                        return
                    }

                    if let fullName = appleIDCredential.fullName {
                        let formatter = PersonNameComponentsFormatter()
                        let nameString = formatter.string(from: fullName).trimmingCharacters(in: .whitespaces)
                        if !nameString.isEmpty {
                            Task {
                                await firebase.setUserSettings(["name": nameString])
                            }
                        }
                    }
                }
            }
        case .failure(let error):
            print("Apple Sign In error: \(error.localizedDescription)")
        }
    }
    
    static func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }

}
