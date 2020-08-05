//
//  AppUser.swift
//  Calm
//
//  Created by Remi Santos on 05/04/2020.
//  Copyright © 2020 Remi Santos. All rights reserved.
//

import Foundation
import FirebaseAuth
import Firebase
import RxCocoa
import CryptoKit
import AuthenticationServices
import FirebaseFirestoreSwift
import Crisp

class AppUserManager : NSObject {
    static let shared = AppUserManager()
    
    fileprivate var isSigningUp: Bool = false
    @objc dynamic var hasUser: Bool = false
    var currentUser:AppUser? {
        didSet {
            hasUser = currentUser != nil
        }
    }
    
    func fetchUserDataIfNeeded() {
        guard let authUser = Auth.auth().currentUser else {
            return
        }
        if (self.currentUser == nil && !self.isSigningUp) {
            UserStore.getAppUser(forAuthId: authUser.uid) { (appUser, error) in
            if let appUser = appUser {
                    AppUser.loginWithUser(user: appUser)
                }
            }
        }
    }
}

struct AppUser: Identifiable {
    
    @DocumentID var id: String?
    var username: String
    let email: String
    let color: PaletteColor!
    let emoji: String
    
    var currentEvent: Event?
    var upcomingEvents: [Event]?
    
    init(withUsername username:String, email: String, color: PaletteColor, emoji: String, uid: String) {
        self.username = username
        self.email = email
        self.color = color
        self.emoji = emoji
        self.id = uid
    }
    
}


// MARK: - Login
extension AppUser {
    static func logout() {
        do {
            try Auth.auth().signOut()
            AppUserManager.shared.currentUser = nil
            Crisp.session.reset()
        } catch { }
    }
    
    static func loginWithUser(user: AppUser) {
        AppUserManager.shared.currentUser = user
        
        Crisp.user.set(email: user.email)
        Crisp.user.set(nickname: user.username)
        Analytics.setUserProperty(user.username, forName: "username")
        Analytics.setUserProperty(user.emoji, forName: "emoji")
        Analytics.setUserProperty(user.color.code, forName: "color")
    }

    static func login(withUsername username: String, password: String, completion:@escaping (_ appUser: AppUser?, _ error: Error?) -> Void) {
        UserStore.getUser(forUsername: username) { (fetchedUser, error) in
            guard let fetchedUser = fetchedUser else {
                completion(nil, error)
                return
            }
            
            Auth.auth().signIn(withEmail: fetchedUser.email, password: password) { (result, error) in
                if let user = result?.user {
                    print("[AppUser]logged in with authId \(user.uid)")
                    UserStore.getAppUser(forAuthId: user.uid) { (appUser, error) in
                        if let appUser = appUser {
                            print("[AppUser] identified as \(String(describing: appUser.username))")
                            AppUser.loginWithUser(user: appUser)
                            completion(appUser, error)
                        } else {
                            print("[AppUser] can't find app user \(String(describing: error))")
                            completion(nil, error)
                        }
                    }
                } else {
                    print("[AppUser] login incorrect \(String(describing: error))")
                    completion(nil, error)
                }
            }
            
        }
    }
    
    static func isUsernameAvailable(_ username: String, completion:@escaping (_ available: Bool, _ error: Error?) -> Void) {
        UserStore.getUser(forUsername: username) { (fetchedUser, error) in
            completion(fetchedUser == nil, error)
        }
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    
    static func signup(withUsername username: String, email: String, password: String?, color: String, emoji: String, authUser: User?, completion:@escaping (_ success: Bool, _ error: Error?) -> Void) {
        AppUserManager.shared.isSigningUp = true
        
        let createAppUser = { (authId: String) in
            UserStore.createUser(withAuthId: authId, username: username, email: email, color: color, emoji: emoji) { (appUser, error) in
                if let appUser = appUser {
                    AppUser.loginWithUser(user: appUser)
                }
                AppUserManager.shared.isSigningUp = false
                completion(appUser != nil, error)
            }
        }

        if let authUser = authUser {
            createAppUser(authUser.uid)
        } else if let password = password {
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                if let user = result?.user {
                    createAppUser(user.uid)
                } else {
                    completion(false, error)
                }
            }
        }
        
    }
    
    // MARK: - Apple Signin
    
    static func signup(withAppleIdCredential appleIDCredential: ASAuthorizationAppleIDCredential, request: ASAuthorizationAppleIDRequest, completion:@escaping (_ appUser: AppUser?, _ authUser:User?, _ error: Error?) -> Void) {
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            completion(nil, nil, nil)
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            completion(nil, nil, nil)
            return
        }
        // Initialize a Firebase credential.
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: self.rawNonce)

        AppUserManager.shared.isSigningUp = true
        Auth.auth().signIn(with: credential) { (authResult, error) in
            guard let user = authResult?.user else {
                if let error = error {
                    print("AppleID auth error \(error.localizedDescription)")
                }
                AppUserManager.shared.isSigningUp = false
                completion(nil, nil, error)
                return
            }
            UserStore.getAppUser(forAuthId: user.uid) { (appUser, error) in
                AppUserManager.shared.isSigningUp = false
                if let appUser = appUser {
                    AppUser.loginWithUser(user: appUser)
                    completion(appUser, user, nil)
                } else {
                    completion(nil, user, error)
                }
            }
        }
    }
    
    private static var rawNonce: String?
    static func buildAppleSigninRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = self.randomNonceString()
        self.rawNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    private static func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private static func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
}

