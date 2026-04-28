import SwiftUI
import FirebaseAuth
import GoogleSignIn
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

            Text("On Belay")
                .font(.largeTitle)
                .bold()

            Spacer()

            // Note: Implementation of Google and Apple sign in requires
            // specific setup in Xcode and Info.plist (URL schemes, etc.)
            // Here we provide the logic flow using Firebase.

            Button(action: signInWithGoogle) {
                HStack {
                    Image(systemName: "g.circle.fill")
                    Text("Sign in with Google")
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

                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                           idToken: idTokenString,
                                                           rawNonce: nil)

                Auth.auth().signIn(with: credential) { _, error in
                    if let error = error {
                        print("Error signing in with Apple: \(error.localizedDescription)")
                    }
                }
            }
        case .failure(let error):
            print("Apple Sign In error: \(error.localizedDescription)")
        }
    }
}
