//
//  SignupViewController.swift
//  killer
//
//  Created by Balnur Sakhybekova on 11/24/19.
//  Copyright © 2019 Zhanna Amanbayeva. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase
import Crashlytics

class SignupViewController: UIViewController {

    
    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // testing crashlitics
        // Crashlytics.sharedInstance().crash()
        setUpElements()
    }
    func setUpElements() {
        errorLabel.alpha = 0
        
        Utilities.styleTextField(firstNameTextField)
        Utilities.styleTextField(lastNameTextField)
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(signUpButton)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func validateFields() -> String? {
        if firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Please, fill in all fields."
        }
        
        let cleanedPassword = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if Utilities.isPasswordValid(cleanedPassword) == false {
            return "Please, make sure your password is 8 character length and contains letters, numbers and signs."
        }
        
        return nil
    }
    

        

    @IBAction func signUpTapped(_ sender: Any) {
        
        let error = validateFields()
        
        if error != nil {
            showError(message: error!)
        }
        else
        {
            let firstName = firstNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let lastName = lastNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
            
            Auth.auth().createUser(withEmail: email, password: password) { (results, err) in
                
                if err != nil
                {
                    self.showError(message: err?.localizedDescription ?? "Error creating user")
                    //self.showError(message: "Error creating user")
                }
                else
                {
                    let db = Firestore.firestore()
                    
                    db.collection("users").addDocument(data: ["firstname": firstName, "lastname": lastName, "uid": results!.user.uid]) { (error) in
                        if error != nil {
                            self.showError(message: "Couldnt save data")
                        }
                    }
                     //if success
                    self.transitionToGameVC()
                }
            }
            
        }
    }
    
    func showError(message : String) {
        errorLabel.text = message
        errorLabel.alpha = 1
    }
    
    func transitionToGameVC(){
    
        if #available(iOS 13.0, *) {
            let gameVC = storyboard?.instantiateViewController(identifier: Constants.Storyboard.gameViewController) as? GameViewController
                view.window?.rootViewController = gameVC
                view.window?.makeKeyAndVisible()
        } else {
            // Fallback on earlier versions
        }
    
    }
}

