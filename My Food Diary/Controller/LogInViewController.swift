//
//  LogInViewController.swift
//  My Food Diary
//
//  Created by Daniel Hilton on 27/11/2019.
//  Copyright © 2019 Daniel Hilton. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD


class LogInViewController: UIViewController {

    typealias FinishedDownload = () -> ()
    
    private let db = Firestore.firestore()
    
    let foodDispatchGroup = DispatchGroup()
    let weightDispatchGroup = DispatchGroup()
    let formatter = DateFormatter()
    var allFood = [Food]()
    var testFoodArray = [Food]()
    var allWeight = [Weight]()
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Color.skyBlue
        logInButton.setTitleColor(Color.skyBlue, for: .normal)
        logInButton.layer.cornerRadius = logInButton.frame.size.height / 2
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        passwordTextField.placeholder = "Password"
        addInputAccessoriesForTextFields(textFields: [emailTextField, passwordTextField], dismissable: true, previousNextable: true)
        
        formatter.dateFormat = "E, d MMM"
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: self.view.window)
    }
    
    
    func loadAllFoodData(user: String?) {
        
        Food.downloadAllFood(user: user!) { (allFood) in
            self.allFood = allFood
            self.foodDispatchGroup.leave()
        }
    }
    
    func loadAllWeightData(user: String?, completed: @escaping FinishedDownload) {
        Weight.downloadAllWeight(user: user!) { (allWeight) in
            self.allWeight = allWeight
            self.weightDispatchGroup.leave()
            completed()
        }
    }
    
    
    
    @IBAction func logInButtonTapped(_ sender: UIButton) {
        
        SVProgressHUD.show()
        passwordTextField.resignFirstResponder()
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            
            if error != nil {
                print(error!)
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            }
            else {
                print("Log In Successful")
                strongSelf.foodDispatchGroup.enter()
                strongSelf.loadAllFoodData(user: authResult?.user.email)
                
                strongSelf.foodDispatchGroup.notify(queue: .main) {
                    strongSelf.weightDispatchGroup.enter()
                    strongSelf.loadAllWeightData(user: authResult?.user.email, completed: { () in
                
                        strongSelf.weightDispatchGroup.notify(queue: .main) {
                            strongSelf.performSegue(withIdentifier: "GoToTabBar", sender: self)
                            SVProgressHUD.dismiss()
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    @objc func viewTapped() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    
    
    
    // Methods to move up/down the messageTableView with the keyboard
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                UIView.animate(withDuration: 0.5) {
                    self.view.frame.origin.y -= (keyboardSize.height - 100)
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            UIView.animate(withDuration: 0.5) {
                self.view.frame.origin.y = 0
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToTabBar" {
            let tabController = segue.destination as! UITabBarController
            let navController = tabController.viewControllers?.first as! UINavigationController
            let pageController = navController.viewControllers.first as! OverviewPageViewController
            pageController.allFood = allFood
            
            let weightNavController = tabController.viewControllers?[1] as! UINavigationController
            let weightVC = weightNavController.viewControllers.first as! WeightViewController
            weightVC.allWeightEntries = allWeight
            
        }
    }
    
}

extension LogInViewController: UITextFieldDelegate {
    
    func addInputAccessoriesForTextFields(textFields: [UITextField], dismissable: Bool = true, previousNextable: Bool = false) {
        for (index, textField) in textFields.enumerated() {
            let toolbar: UIToolbar = UIToolbar()
            toolbar.sizeToFit()

            var items = [UIBarButtonItem]()
            if previousNextable {
                let previousButton = UIBarButtonItem(image: UIImage(named: "UpArrow"), style: .plain, target: nil, action: nil)
                previousButton.width = 20
                if textField == textFields.first {
                    previousButton.isEnabled = false
                } else {
                    previousButton.target = textFields[index - 1]
                    previousButton.action = #selector(UITextField.becomeFirstResponder)
                }

                let nextButton = UIBarButtonItem(image: UIImage(named: "DownArrow"), style: .plain, target: nil, action: nil)
                nextButton.width = 20
                if textField == textFields.last {
                    nextButton.isEnabled = false
                } else {
                    nextButton.target = textFields[index + 1]
                    nextButton.action = #selector(UITextField.becomeFirstResponder)
                }
                items.append(contentsOf: [previousButton, nextButton])
            }

            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: view, action: #selector(UIView.endEditing))
            items.append(contentsOf: [spacer, doneButton])


            toolbar.setItems(items, animated: false)
            textField.inputAccessoryView = toolbar
        }
    }
    

}
