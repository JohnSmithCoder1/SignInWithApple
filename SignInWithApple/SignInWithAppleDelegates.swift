/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import AuthenticationServices

class SignInWithAppleDelegates: NSObject {
  private let signInSucceeded: (Bool) -> Void

  init(onSignedIn: @escaping (Bool) -> Void) {
    self.signInSucceeded = onSignedIn
  }
}

extension SignInWithAppleDelegates: ASAuthorizationControllerDelegate {
  // Credential.user is the unique identifier assigned by Apple that we'll use to identify the user in our system
  private func registerNewAccount(credential: ASAuthorizationAppleIDCredential) {
    let userData = UserData(email: credential.email!,
                            name: credential.fullName!,
                            identifier: credential.user)
    
    let keychain = UserDataKeychain()
    
    // Store the data in the iCloud keychain
    do {
      try keychain.store(userData)
    } catch {
      self.signInSucceeded(false)
    }
    
    do {
      let success = try WebApi.Register(user: userData,
                                        identityToken: credential.identityToken,
                                        authorizationCode: credential.authorizationCode
      )
      
      self.signInSucceeded(success)
    } catch {
      self.signInSucceeded(false)
    }
  }
  
  // Apple will only provide this data on the FIRST successful authorization then never again, so make sure it is saved appropriately on the back end or temporarily store it until the database insertion can be successfully completed (in case of bad network or database connection, etc.)
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    switch authorization.credential {
    case let appleIdCredential as ASAuthorizationAppleIDCredential:

      if let _ = appleIdCredential.email, let _ = appleIdCredential.fullName {
        registerNewAccount(credential: appleIdCredential)
      } else {
        signInWithExistingAccount(credential: appleIdCredential)
      }
      
      break

    case let passwordCredential as ASPasswordCredential:

      break

    default:
      break
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
  }
}
