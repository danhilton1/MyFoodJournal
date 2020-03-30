//
//  NewEntryPopUpViewController.swift
//  Eat Me
//
//  Created by Daniel Hilton on 28/06/2019.
//  Copyright © 2019 Daniel Hilton. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class NewEntryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let db = Firestore.firestore()
    
    //IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var enterManuallyButton: UIButton!
    @IBOutlet weak var historyLabel: UILabel!
    @IBOutlet weak var multiAddButton: UIButton!
    
    //MARK:- Properties
    
    var date: Date?
    var meal = Food.Meal.breakfast
    weak var delegate: NewEntryDelegate?
    weak var mealDelegate: NewEntryDelegate?
    var allFood: [Food]?
    private var sortedFood = [Food]()
    private var sortedFoodCopy = [Food]()
    
    
    enum Segues {
        static let goToManualEntry = "GoToManualEntry"
        static let goToBarcodeScanner = "GoToBarcodeScanner"
        static let goToFoodDetail = "GoToFoodDetail"
    }
    
    //MARK:- View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpNavBar()
        
        setUpSortedFoodList()
        sortedFoodCopy = sortedFood
        
        setUpTableView()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        presentingViewController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        presentingViewController?.tabBarController?.tabBar.isHidden = false
    }
    
    func setUpNavBar() {
        let dismissButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        dismissButton.setImage(UIImage(named: "plus-icon"), for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        dismissButton.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4))
        dismissButton.imageView?.clipsToBounds = false
        dismissButton.imageView?.contentMode = .center
        let barButton = UIBarButtonItem(customView: dismissButton)
        navigationItem.leftBarButtonItem = barButton
        
        navigationController?.navigationBar.barTintColor = Color.skyBlue
        
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        } else {
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        tableView.tableFooterView = UIView()
        tableView.allowsMultipleSelection = true
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    func setUpSortedFoodList() {
        var foodDictionary = [String: Food]()
        for food in allFood! {
            foodDictionary[food.name!] = food
        }
        sortedFood = foodDictionary.values.sorted { (food1, food2) -> Bool in
            guard
                let food1Date = food1.dateCreated,
                let food2Date = food2.dateCreated
            else {
                return false
            }
            return food1Date > food2Date
        }
    }

    //MARK:- Button Methods
    
    @objc func dismissButtonTapped(_ sender: UIBarButtonItem) {
        dismissViewWithAnimation()
    }
    
    @IBAction func multiAddButton(_ sender: UIButton) {
        tableView.isEditing = !tableView.isEditing
        
        if tableView.isEditing {
            multiAddButton.setTitle("Cancel", for: .normal)
            let tickButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            tickButton.setImage(UIImage(named: "tick-icon"), for: .normal)
            tickButton.addTarget(self, action: #selector(tickButtonTapped), for: .touchUpInside)
            tickButton.imageView?.clipsToBounds = false
            tickButton.imageView?.contentMode = .center
            let barButton = UIBarButtonItem(customView: tickButton)
            navigationItem.rightBarButtonItem = barButton
        }
        else {
            multiAddButton.setTitle("Multi-add", for: .normal)
            navigationItem.rightBarButtonItem = nil
        }
        
        
    }
    
    @objc func tickButtonTapped() {
        
        if tableView.indexPathsForSelectedRows != nil {
            let ac = UIAlertController(title: "Please select the meal you would like these foods to be entered for.", message: nil, preferredStyle: .actionSheet)
            
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            ac.addAction(UIAlertAction(title: "Breakfast", style: .default) { [weak self] (action) in
                self?.addSelectedFoods(for: .breakfast)
            })
            ac.addAction(UIAlertAction(title: "Lunch", style: .default) { [weak self] (action) in
                self?.addSelectedFoods(for: .lunch)
            })
            ac.addAction(UIAlertAction(title: "Dinner", style: .default) { [weak self] (action) in
                self?.addSelectedFoods(for: .dinner)
            })
            ac.addAction(UIAlertAction(title: "Other", style: .default) { [weak self] (action) in
                self?.addSelectedFoods(for: .other)
            })
            
            present(ac, animated: true)
        }
        else {
            let ac = UIAlertController(title: "No foods selected", message: "Please select a food you want to add.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
    }
    
    func addSelectedFoods(for meal: Food.Meal) {
        
        guard let user = Auth.auth().currentUser?.uid else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM"
        
        if let indexPaths = tableView.indexPathsForSelectedRows {
            var food: Food
            
            for indexPath in indexPaths {
                food = sortedFoodCopy[indexPath.row].copy()
                
                food.date = formatter.string(from: date ?? Date())
                food.dateLastEdited = Date()
                food.isDeleted = false
                food.meal = meal.stringValue
                food.dateCreated = Date()
                food.uuid = UUID().uuidString
                
                food.saveFood(user: user)
                
                delegate?.reloadFood(entry: food, new: true)
                
            }
            dismissViewWithAnimation()
        }
        else {
            let ac = UIAlertController(title: "Error", message: "Please make sure have you selected at least one food to add.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
    }
    
    func dismissViewWithAnimation() {
        let transition: CATransition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.reveal
        transition.subtype = CATransitionSubtype.fromBottom
        self.view.window!.layer.add(transition, forKey: nil)
        self.dismiss(animated: false, completion: nil)
    }
    

    //MARK:- Segue Method
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.goToManualEntry {
            let destVC = segue.destination as! ManualEntryViewController
            destVC.delegate = delegate
            destVC.mealDelegate = mealDelegate
            destVC.date = date
            destVC.selectedSegmentIndex = meal.intValue
        }
        else if segue.identifier == Segues.goToBarcodeScanner {
            let destVC = segue.destination as! BarcodeScannerViewController
            destVC.date = date
            destVC.delegate = delegate
            destVC.mealDelegate = mealDelegate
            destVC.selectedSegmentIndex = meal.intValue
        }
        else if segue.identifier == Segues.goToFoodDetail {
            let destVC = segue.destination as! FoodDetailViewController
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            destVC.food = sortedFoodCopy[indexPath.row]
            destVC.delegate = delegate
            destVC.mealDelegate = mealDelegate
            destVC.date = date
            destVC.selectedSegmentIndex = meal.intValue
        }
    }
}

//MARK:- Extension for table view and search bar methods

extension NewEntryViewController: UISearchBarDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sortedFoodCopy.count == 0 {  // If foodList is empty, return 1 cell in order to display message
            return 1
        }
        return sortedFoodCopy.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell()
        defaultCell.textLabel?.font = UIFont(name: "Montserrat-Regular", size: 16)
       
        if sortedFoodCopy.count == 0 {
            tableView.separatorStyle = .none
            if historyLabel.text == "History" {
                defaultCell.textLabel?.text = "No food logged."
            }
            else {
                defaultCell.textLabel?.text = "No matching foods found."
            }
            return defaultCell
        }
        else {
            tableView.separatorStyle = .singleLine
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "foodHistoryCell", for: indexPath) as! FoodHistoryCell
        cell.foodNameLabel.text = sortedFoodCopy[indexPath.row].name
        cell.caloriesLabel.text = "\(sortedFoodCopy[indexPath.row].calories) kcal"
        
        if UIScreen.main.bounds.height < 600 {
            cell.caloriesLabel.font = cell.caloriesLabel.font.withSize(14)
            cell.calorieNameEqualWidthConstraint.constant = -135
        }

        var totalServing = sortedFoodCopy[indexPath.row].totalServing
        let unit = sortedFoodCopy[indexPath.row].servingSizeUnit
        cell.totalServingLabel.text = totalServing.removePointZeroEndingAndConvertToString() + " \(unit)"

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.isEditing {
            performSegue(withIdentifier: Segues.goToFoodDetail, sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let ac = UIAlertController(title: "Delete Food", message: "Are you sure you want to permanently delete this item and all entries of it?", preferredStyle: .alert)
            
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] (action) in
                guard let strongSelf = self else { return }
                
                let currentNav = strongSelf.parent as! UINavigationController
                let overviewNav = currentNav.presentingViewController as! UINavigationController
                let overviewPVC = overviewNav.viewControllers.first as! OverviewPageViewController
                let overviewVC = overviewPVC.viewControllers?.first as! OverviewViewController
                
                var index = 0
                for entry in strongSelf.allFood! {
                    if entry.name == strongSelf.sortedFoodCopy[indexPath.row].name {
                        strongSelf.deleteFirestoreFoodDocument(withName: entry.name!, uuid: entry.uuid)
                        strongSelf.allFood?.remove(at: index)
                        overviewPVC.allFood.remove(at: index)
                        overviewVC.allFood?.remove(at: index)
                        index -= 1
                    }
                    index += 1
                }
                overviewVC.loadFoodData()
                strongSelf.sortedFoodCopy.remove(at: indexPath.row)
                strongSelf.tableView.deleteRows(at: [indexPath], with: .automatic)
                
            })
            present(ac, animated: true)
        }
    }
    
    func deleteFirestoreFoodDocument(withName name: String, uuid: String) {
        guard let user = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(user).collection("foods").document("\(name) \(uuid)").delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document: \(name) successfully removed!")
            }
        }
    }
    
    //MARK:- Search Bar Delegate methods
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText != "" {
            sortedFoodCopy = []
            for food in sortedFood {
                if (food.name?.lowercased().contains(searchBar.text!.lowercased()))! {
                    sortedFoodCopy.append(food)
                }
            }
            tableView.reloadData()
        }
        else {
            historyLabel.text = "History"
            sortedFoodCopy = sortedFood
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if let searchText = searchBar.text {
            var searchWords = searchText.replacingOccurrences(of: "’", with: "%27")
            searchWords = searchWords.replacingOccurrences(of: " ", with: "+")
            searchWords = searchWords.replacingOccurrences(of: "%", with: "%25")
            searchWords = searchWords.filter("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789&/-+%".contains)
            
            SVProgressHUD.setBackgroundColor(.darkGray)
            SVProgressHUD.setForegroundColor(.white)
            SVProgressHUD.show()
            
            DatabaseServices.getItems(withKeywords: searchWords) { (success, items) in
                if success {
                    self.sortedFoodCopy = items
                    self.tableView.reloadData()
                    self.historyLabel.text = "Results"
                    searchBar.resignFirstResponder()
                    SVProgressHUD.dismiss()
                }
                else {
                    print("Error retrieving data")
                    SVProgressHUD.showError(withStatus: "Error retrieving items - please check your internet connection.")
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        SVProgressHUD.dismiss()
        searchBar.text = ""
        searchBar.resignFirstResponder()
        sortedFoodCopy = sortedFood
        if historyLabel.text == "Results" {
            historyLabel.text = "History"
        }
        tableView.reloadData()
    }
    
}
