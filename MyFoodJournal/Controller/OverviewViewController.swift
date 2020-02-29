//
//  ViewController.swift
//  Eat Me
//
//  Created by Daniel Hilton on 19/05/2019.
//  Copyright © 2019 Daniel Hilton. All rights reserved.


import UIKit
import Charts
import Firebase

class OverviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NewEntryDelegate {

    
    //MARK: - Properties
    
    var date: Date?   //  Required to be set before VC presented
    var foodEntries: [Food]?
    var allFood: [Food]?
    private var totalCalsArray = [Int]()
    private var refreshControl = UIRefreshControl()
    private let formatter = DateFormatter()
    private let defaults = UserDefaults()
    private let food = Food()
    private var totalCalories = 0
    private var remainingCalories = 0
    private var calorieArray = [Int]()
    private var proteinArray = [Double]()
    private var carbsArray = [Double]()
    private var fatArray = [Double]()
    private var calories = 0
    private var protein = 0.0
    private var carbs = 0.0
    private var fat = 0.0
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    private let datePicker = UIDatePicker()
    override var inputView: UIView? {
        datePicker.date = date ?? Date()
        return self.datePicker
    }
    override var inputAccessoryView: UIView? {
        return self.toolbar
    }
    private let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
       
    private let dimView = UIView()
    
    
    //IBOutlets
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var eatMeTableView: UITableView!
    @IBOutlet weak var totalCaloriesTextLabel: UILabel!
    @IBOutlet weak var totalCaloriesLabel: UILabel!
    @IBOutlet weak var goalCaloriesTextLabel: UILabel!
    @IBOutlet weak var goalCaloriesLabel: UILabel!
    @IBOutlet weak var remainingCaloriesTextLabel: UILabel!
    @IBOutlet weak var remainingCaloriesLabel: UILabel!
    
    @IBOutlet weak var totalCalsTextLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var goalCalsTextLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var remainingCalsTextLabelHeightConstraint: NSLayoutConstraint!
    
    
    //MARK: - view Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
        checkDeviceAndUpdateConstraints()
        
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        eatMeTableView.addSubview(refreshControl)
        
        configureDateView()
        loadFoodData()
        
        setUpToolBar()
        datePicker.datePickerMode = .date
        datePicker.locale = Locale.current
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissResponder))
        dimView.addGestureRecognizer(tapGesture)
        
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        loadFoodData()
        configureTotalCaloriesLabel()
        presentingViewController?.tabBarController?.tabBar.isHidden = false
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        dimView.removeFromSuperview()
    }

    
    private func setUpTableView() {
        eatMeTableView.delegate = self
        eatMeTableView.dataSource = self
        eatMeTableView.separatorStyle = .none
        eatMeTableView.register(UINib(nibName: "MealOverviewCell", bundle: nil), forCellReuseIdentifier: "mealOverviewCell")
    }
    
    private func setUpToolBar() {
        self.toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissResponder)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(todayTapped)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dateEntered))
        ]
        self.toolbar.sizeToFit()
    }
    
    private func configureDateView() {
        formatter.dateFormat = "E, d MMM"
        guard let date = date else { return }
        let dateAsString = formatter.string(from: date)
        
        // Check if date is the same as current date and if so, display "Today" in label
        if dateAsString == formatter.string(from: Date()) {
            dayLabel.text = "Today"
        } else {
            dayLabel.text = dateAsString
        }
    }
    
    private func configureTotalCaloriesLabel() {
        let goalCalories = defaults.value(forKey: UserDefaultsKeys.goalCalories) as? Int ?? 0
        goalCaloriesLabel.text = "\(goalCalories)"
        if totalCalories < (goalCalories - 500) || totalCalories > (goalCalories + 500) || goalCalories == 0 {
            totalCaloriesLabel.textColor = Color.salmon
            remainingCaloriesLabel.textColor = Color.salmon
        }
        else if totalCalories >= (goalCalories - 100) && totalCalories <= (goalCalories + 100) {
            totalCaloriesLabel.textColor = Color.mint
            remainingCaloriesLabel.textColor = Color.mint
        }
        else {
            totalCaloriesLabel.textColor = .systemOrange
            remainingCaloriesLabel.textColor = .systemOrange
        }
    }
    
    func checkDeviceAndUpdateConstraints() {
        if UIScreen.main.bounds.height < 600 {
            totalCaloriesTextLabel.font = totalCaloriesTextLabel.font.withSize(15)
            goalCaloriesTextLabel.font = goalCaloriesTextLabel.font.withSize(15)
            remainingCaloriesTextLabel.font = remainingCaloriesTextLabel.font.withSize(14.5)
            totalCaloriesLabel.font = totalCaloriesLabel.font.withSize(15)
            goalCaloriesLabel.font = goalCaloriesLabel.font.withSize(15)
            remainingCaloriesLabel.font = remainingCaloriesLabel.font.withSize(15)
            
            totalCalsTextLabelHeightConstraint.constant = 30
            goalCalsTextLabelHeightConstraint.constant = 30
            remainingCalsTextLabelHeightConstraint.constant = 60
        }
        else if UIScreen.main.bounds.height < 700 {
            let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.tabBarController!.tabBar.frame.height / 2, right: 0)
            self.eatMeTableView.contentInset = adjustForTabbarInsets
            self.eatMeTableView.scrollIndicatorInsets = adjustForTabbarInsets
        }
    }
    
    
    
    //MARK:- Data methods
    
    func loadFoodData() {
        
        formatter.dateFormat = "E, d MMM"
        
        foodEntries = [Food]()
        
        if let allFoodEntries = allFood {
            for food in allFoodEntries {
                if food.date == formatter.string(from: date ?? Date()) && !food.isDeleted {
                    foodEntries!.append(food)
                }
            }
        }

        for food in foodEntries! {
            totalCalsArray.append(food.calories)
        }
        var tempTotalCalories = 0
        tempTotalCalories = totalCalsArray.reduce(0, +)
        totalCalories = tempTotalCalories
        let goalCalories = defaults.value(forKey: UserDefaultsKeys.goalCalories) as? Int ?? totalCalories
        remainingCalories = goalCalories - totalCalories
        remainingCaloriesLabel.text = "\(remainingCalories)"
        totalCaloriesLabel.text = "\(tempTotalCalories)"
        configureTotalCaloriesLabel()
        totalCalsArray = []
        tempTotalCalories = 0
        
        eatMeTableView.reloadData()

    }
    
    @objc func refresh() {
        loadFoodData()
        refreshControl.endRefreshing()
    }
    
    
    
    
    //MARK: - Methods to Update UI with user's entry data
    
    
    private func getTotalValueOfMealData(food: [Food]?, meal: Food.Meal, cell: MealOverviewCell) {
        // Updates the total amount of cals and macros for user entries
        
        // Checks the meal type and then appends each food property (cals, carbs, ..) to corresponding array

        if let foodList = food {
            switch meal {
            case .breakfast:
                retrieveNutritionData(meal: Food.Meal.breakfast.stringValue, foodList: foodList)
            case .lunch:
                retrieveNutritionData(meal: Food.Meal.lunch.stringValue, foodList: foodList)
            case .dinner:
                retrieveNutritionData(meal: Food.Meal.dinner.stringValue, foodList: foodList)
            default:
                retrieveNutritionData(meal: Food.Meal.other.stringValue, foodList: foodList)
            }
        }
        
        cell.calorieLabel.text = "\(calories) kcal"
        cell.proteinLabel.text = protein.removePointZeroEndingAndConvertToString() + " g"
        cell.carbsLabel.text = carbs.removePointZeroEndingAndConvertToString() + " g"
        cell.fatLabel.text = fat.removePointZeroEndingAndConvertToString() + " g"
        
        setUpPieChart(cell: cell, section1: protein, section2: carbs, section3: fat)
        
        calorieArray = []
        proteinArray = []
        carbsArray = []
        fatArray = []
        calories = 0
        protein = 0
        carbs = 0
        fat = 0
    }
    
    private func retrieveNutritionData(meal: String, foodList: [Food]) {
        
        for food in foodList {
            if food.meal == meal {
                calorieArray.append(food.calories)
                proteinArray.append(food.protein)
                carbsArray.append(food.carbs)
                fatArray.append(food.fat)
                }
        }
        for i in 0..<calorieArray.count {
            calories += calorieArray[i]
            protein += proteinArray[i]
            carbs += carbsArray[i]
            fat += fatArray[i]
        }
        
    }
    
    
    func setUpPieChart(cell: MealOverviewCell, section1 protein: Double, section2 carbs: Double, section3 fat: Double) {
        
        cell.pieChart.legend.enabled = false
        cell.pieChart.holeRadiusPercent = 0.5
        cell.pieChart.highlightPerTapEnabled = false
        cell.pieChart.rotationEnabled = false
        
        // If no user entries/data then set default equal values of pie chart to display equal sections
        if protein == 0 && carbs == 0 && fat == 0 {
            
            let chartDataSet = PieChartDataSet(entries: [PieChartDataEntry(value: 1.0),
                                                         PieChartDataEntry(value: 1.0),
                                                         PieChartDataEntry(value: 1.0)], label: nil)
            chartDataSet.drawValuesEnabled = false
            chartDataSet.colors = [Color.mint, Color.skyBlue, Color.salmon]
            chartDataSet.selectionShift = 0
            let chartData = PieChartData(dataSet: chartDataSet)
            
            cell.pieChart.data = chartData
            
        } else {
            // Set pie chart data to the total values of protein, carbs and fat from user's entries
            let pieChartEntries = [PieChartDataEntry(value: protein),
                                   PieChartDataEntry(value: carbs),
                                   PieChartDataEntry(value: fat)]
            let chartDataSet = PieChartDataSet(entries: pieChartEntries, label: nil)
            chartDataSet.drawValuesEnabled = false
            chartDataSet.colors = [Color.mint, Color.skyBlue, Color.salmon]
            chartDataSet.selectionShift = 0
            let chartData = PieChartData(dataSet: chartDataSet)
            
            cell.pieChart.data = chartData
        }
    }
    
    
    //MARK:- Button Methods
    
    @IBAction func dateButtonTapped(_ sender: UIButton) {
        datePickerArrowTapped(sender)
    }
    
    
    @IBAction func datePickerArrowTapped(_ sender: UIButton) {
        
        dimView.frame = self.view.frame
        dimView.backgroundColor = .black
        dimView.alpha = 0
        self.view.addSubview(dimView)
        UIView.animate(withDuration: 0.25) {
            self.dimView.alpha = 0.35
            
        }
        self.becomeFirstResponder()
    }

    
    @objc func dateEntered() {
        self.resignFirstResponder()
        
        UIView.animate(withDuration: 0.2) {
            self.dimView.alpha = 0
        }
        
        let previousDate = date
        date = datePicker.date
        let parentVC = parent as? OverviewPageViewController
        parentVC?.dateEnteredFromPicker = true
        parentVC?.dateFromDatePicker = datePicker.date
        
        
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut, animations: {
            if self.date! > previousDate! {
                self.eatMeTableView.frame = self.eatMeTableView.frame.offsetBy(dx: -self.eatMeTableView.frame.width, dy: 0)
            }
            else if self.date! < previousDate! {
                self.eatMeTableView.frame = self.eatMeTableView.frame.offsetBy(dx: self.eatMeTableView.frame.width, dy: 0)
            }
            var viewRightFrame = self.eatMeTableView.frame
            viewRightFrame.origin.x += viewRightFrame.size.width
            var viewLeftFrame = self.eatMeTableView.frame
            viewLeftFrame.origin.x -= viewLeftFrame.size.width
            if self.date! > previousDate! {
                self.eatMeTableView.frame = viewLeftFrame
            }
            else if self.date! < previousDate! {
                self.eatMeTableView.frame = viewRightFrame
            }
            
        }) { (success) in
            parentVC?.setViewControllers([self], direction: .forward, animated: false, completion: nil)
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
            self.dimView.removeFromSuperview()
            self.loadFoodData()
            self.configureDateView()
        }
    }
    
    @objc func todayTapped() {
        datePicker.date = Date()
    }
    
    @objc func dismissResponder() {
        self.resignFirstResponder()
        UIView.animate(withDuration: 0.2) {
            self.dimView.alpha = 0
        }
    }

    
    @IBAction func goalButtonTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Goal Calories", message: "Please set your goal calories", preferredStyle: .alert)
        
        ac.addTextField { (textField) in
            textField.text = "\(self.defaults.value(forKey: "GoalCalories") ?? "")"
            textField.placeholder = "Enter value here"
            textField.keyboardType = .numberPad
        }
        
        ac.addAction(UIAlertAction(title: "Set", style: .default, handler: { (UIAlertAction) in
            self.defaults.setValue(Int(ac.textFields![0].text ?? "0"), forKey: "GoalCalories")
            self.goalCaloriesLabel.text = "\(self.defaults.value(forKey: "GoalCalories") ?? 0)"
            self.loadFoodData()
            self.configureTotalCaloriesLabel()
            let parentVC = self.parent as? OverviewPageViewController
            parentVC?.setViewControllers([self], direction: .forward, animated: false, completion: nil)
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(ac, animated: true)
    }
    
    //MARK:- NewEntryDelegate protocol method
    
    
    func reloadFood(entry: Food?, new: Bool) {
        if let food = entry {
            if new {
                allFood?.append(food)
                let pageVC = parent as? OverviewPageViewController
                pageVC?.allFood.append(food)
            }
            else {
                
                for foodEntry in allFood! {
                    if foodEntry.uuid == food.uuid {
                        foodEntry.date = food.date
                        foodEntry.dateCreated = food.dateCreated
                        foodEntry.dateLastEdited = food.dateLastEdited
                        foodEntry.meal = food.meal
                        foodEntry.serving = food.serving
                        foodEntry.calories = food.calories
                        foodEntry.protein = food.protein
                        foodEntry.carbs = food.carbs
                        foodEntry.fat = food.fat
                        foodEntry.sugar = food.sugar
                        foodEntry.saturatedFat = food.saturatedFat
                        foodEntry.fibre = food.fibre
                        foodEntry.isDeleted = food.isDeleted
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            self.loadFoodData()
        }
        if dayLabel.text == "Today" {  // Keeps the date property up to date when navigating from other VC's
            date = Date()
        }
        else {
            date = date?.addingTimeInterval(1) // Makes sure no food can have exactly the same date and time added
        }
        let parentVC = self.parent as? OverviewPageViewController
        parentVC?.setViewControllers([self], direction: .forward, animated: false, completion: nil)
    }
    
    //MARK:- Configure date method
    
    func configureWith(date: Date) {
        self.date = date
    }
    
    
    //MARK:- Segue Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier ==  "goToMealDetail" {
            
            let destVC = segue.destination as! MealDetailViewController
            destVC.delegate = self
            destVC.date = date
            destVC.allFood = allFood
            
            if let indexPath = eatMeTableView.indexPathForSelectedRow {
                
                if indexPath.section == 0 {
                    filterFoodForMealDetail(meal: Food.Meal.breakfast, destVC: destVC)
                }
                else if indexPath.section == 1 {
                    filterFoodForMealDetail(meal: Food.Meal.lunch, destVC: destVC)
                }
                else if indexPath.section == 2 {
                    filterFoodForMealDetail(meal: Food.Meal.dinner, destVC: destVC)
                }
                else if indexPath.section == 3 {
                    filterFoodForMealDetail(meal: Food.Meal.other, destVC: destVC)
                }
            }
        }
        else if segue.identifier == "GoToNutrition" {
            let navController = segue.destination as! UINavigationController
            let destVC = navController.viewControllers.first as! NutritionViewController
            destVC.allFood = allFood
            destVC.date = date
            destVC.calories = totalCalories
        }
    }
    
    func filterFoodForMealDetail(meal: Food.Meal, destVC: MealDetailViewController) {
        
        destVC.navigationItem.title = meal.stringValue
        destVC.meal = meal
        
        var sortedFood = [Food]()

        var foodDictionary = [String: Food]()
        for food in foodEntries! {
            if food.meal == meal.stringValue && !food.isDeleted {
                foodDictionary[food.name!] = food
            }
        }
        sortedFood = foodDictionary.values.sorted { (food1, food2) -> Bool in
            guard
                let food1Date = food1.dateCreated,
                let food2Date = food2.dateCreated
            else {
                return false
            }
            return food1Date < food2Date
        }
        
        destVC.selectedFoodList = sortedFood
        
    }
    
}

//MARK: - Tableview Data Source/Delegate Methods

extension OverviewViewController {
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let label = UILabel()
        label.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        label.textColor = UIColor.black
        if UIScreen.main.bounds.height < 600 {
            label.font = UIFont(name: "Montserrat-SemiBold", size: 14)
        }
        else {
            label.font = UIFont(name: "Montserrat-SemiBold", size: 16)
        }
        
        switch section {
        case 0:
            label.text = "   Breakfast"
        case 1:
            label.text = "   Lunch"
        case 2:
            label.text = "   Dinner"
        case 3:
            label.text = "   Other"
        default:
            label.text = ""
        }
        
        return label
            
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UIScreen.main.bounds.height < 600 {
            return 110
        }
        else if UIScreen.main.bounds.height < 800 {
            return 114
        }
        else if UIScreen.main.bounds.height < 850 {
            return 108
        }
        else {
          return 120
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if UIScreen.main.bounds.height < 850 {
            return 22
        }
        else {
          return 25
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "mealOverviewCell", for: indexPath) as! MealOverviewCell
        
        switch indexPath.section {
            
        case 0:
            getTotalValueOfMealData(food: foodEntries, meal: .breakfast, cell: cell)
        case 1:
            getTotalValueOfMealData(food: foodEntries, meal: .lunch, cell: cell)
        case 2:
            getTotalValueOfMealData(food: foodEntries, meal: .dinner, cell: cell)
        case 3:
            getTotalValueOfMealData(food: foodEntries, meal: .other, cell: cell)
        default:
            cell.calorieLabel.text = "0"
            cell.proteinLabel.text = "0"
            cell.carbsLabel.text = "0"
            cell.fatLabel.text = "0"
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "goToMealDetail", sender: nil)
        tableView.deselectRow(at: indexPath, animated: false)
        
    }
}

//MARK:- Extension for type Double to add formatting/rounding functions

extension Double {
    
    mutating func roundToXDecimalPoints(decimalPoints: Int?) -> Double {
        switch decimalPoints {
        case 1:
            return Darwin.round(10 * self) / 10
        case 2:
            return Darwin.round(100 * self) / 100
        case 3:
            return Darwin.round(1000 * self) / 1000
        case 4:
            return Darwin.round(10000 * self) / 10000
        case 5:
            return Darwin.round(100000 * self) / 100000
        case 6:
            return Darwin.round(1000000 * self) / 1000000
        case 7:
            return Darwin.round(10000000 * self) / 10000000
        case 8:
            return Darwin.round(100000000 * self) / 100000000
        case 9:
            return Darwin.round(1000000000 * self) / 1000000000
        case 10:
            return Darwin.round(10000000000 * self) / 10000000000
        default:
            return Darwin.round(self)
            
        }
    }
    
    mutating func removePointZeroEndingAndConvertToString() -> String {
        var numberString = String(self.roundToXDecimalPoints(decimalPoints: 1))

        if numberString.hasSuffix(".0") {
            numberString.removeLast(2)
        }
        return numberString
    }
    
    mutating func roundWholeAndRemovePointZero() -> String {
        let value = Darwin.round(self)
        var valueString = String(value)
        
        if valueString.hasSuffix(".0") {
            valueString.removeLast(2)
        }
        return valueString
    }
}




