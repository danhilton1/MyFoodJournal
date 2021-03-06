//
//  ForgotPasswordViewController.swift
//  My Food Diary
//
//  Created by Daniel Hilton on 26/01/2020.
//  Copyright © 2020 Daniel Hilton. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {

    //MARK:- Properties
    
    private let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    
    // IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var emailTextField: LogInTextField!
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var emailTextFieldHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var submitButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var submitButtonTopConstraint: NSLayoutConstraint!
    
    //MARK:- View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViews()
        checkDeviceAndUpdateConstraints()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)
        
    }
    
    func setUpViews() {
        view.backgroundColor = Color.skyBlue
        emailTextField.placeholder = "Email address"
        emailTextField.layer.cornerRadius = 20
        emailTextField.setLeftPaddingPoints(6)
        emailTextField.keyboardType = .emailAddress
        submitButton.layer.cornerRadius = 22
        submitButton.setTitleColor(Color.skyBlue, for: .normal)
        
        self.toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(viewTapped))
        ]
        self.toolbar.sizeToFit()
        emailTextField.inputAccessoryView = toolbar
    }
    
    func checkDeviceAndUpdateConstraints() {
        if UIScreen.main.bounds.height < 600 {
            titleLabel.font = titleLabel.font.withSize(24)
            textLabel.font = textLabel.font.withSize(14)
            emailTextFieldHeightConstraint.constant = 35
            emailTextField.font = emailTextField.font?.withSize(14)
            submitButtonHeightConstraint.constant = 35
            submitButtonTopConstraint.constant = 50
            submitButton.titleLabel?.font = submitButton.titleLabel?.font.withSize(17)
            emailTextField.layer.cornerRadius = 19
            submitButton.layer.cornerRadius = 18
        }
    }
    
    //MARK:- Button Methods
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        if let email = emailTextField.text {
            SVProgressHUD.show()
            Auth.auth().sendPasswordReset(withEmail: email) { [weak self] (error) in
                guard let strongSelf = self else { return }
                
                if let error = error {
                    print(error)
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                }
                else {
                    UIView.animate(withDuration: 0.2) {
                        strongSelf.emailTextField.alpha = 0
                        strongSelf.submitButton.alpha = 0
                        strongSelf.textLabel.alpha = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        strongSelf.emailTextField.removeFromSuperview()
                        strongSelf.submitButton.removeFromSuperview()
                        strongSelf.textLabel.alpha = 1
                        strongSelf.textLabel.numberOfLines = 4
                        strongSelf.textLabel.text = "Password reset link sent to entered email address. Please check your inbox and follow instructions to reset your password."
                        SVProgressHUD.setMinimumDismissTimeInterval(2)
                        SVProgressHUD.showSuccess(withStatus: "Password reset link sent")
                    }
                    SVProgressHUD.dismiss()
                }
            }
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @objc func viewTapped() {
        emailTextField.resignFirstResponder()
    }
    
}
