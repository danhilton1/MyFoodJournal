//
//  MonthNutritionViewController.swift
//  Eat Me
//
//  Created by Daniel Hilton on 12/10/2019.
//  Copyright © 2019 Daniel Hilton. All rights reserved.
//

import UIKit
import Charts


class MonthNutritionViewController: WeekNutritionViewController {
    
    var monthAverageProtein: Double?
    var monthAverageCarbs: Double?
    var monthAverageFat: Double?
    var monthAverageCalories: Double?
    var direction: Calendar.SearchDirection = .backward
    
    
    func getAverageValueOfNutrient(entries: [ChartDataEntry], nutrient: Double) -> Double {
        var numberOfEntries = 0.0
        var nutrient = nutrient
        for value in entries {
            if value.y > 0 {
                nutrient += value.y
                numberOfEntries += 1
            }
        }
        nutrient = nutrient / numberOfEntries
        
        if nutrient.isNaN {
            nutrient = 0
        }
        
        return nutrient
    }
    
    //MARK:- Tableview Data Source/Delegate Methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BarNutritionCell", for: indexPath) as! BarChartNutritionCell
            
            let VC = parent as? NutritionViewController
            
            cell.barChart.xAxis.granularityEnabled = true
            var chartData: BarChartData
            
            if direction == .backward {
                cell.barChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: VC?.monthChartLabels.reversed() ?? ["1", "2", "3", "4", "5"])

                cell.barChart.xAxis.axisMaximum = Double(proteinChartDataSet.count)
                let reversedProteinDataSet = BarChartDataSet(entries: proteinChartDataSet.reversed(), label: "Av. Protein / Day")
                let reversedCarbsDataSet = BarChartDataSet(entries: carbsChartDataSet.reversed(), label: "Av. Carbs / Day")
                let reversedFatDataSet = BarChartDataSet(entries: fatChartDataSet.reversed(), label: "Av. Fat / Day")
                let chartDataSets = [reversedProteinDataSet, reversedCarbsDataSet, reversedFatDataSet]
                
                reversedProteinDataSet.colors = [Color.mint]
                reversedCarbsDataSet.colors = [Color.skyBlue]
                reversedFatDataSet.colors = [Color.salmon]
                reversedProteinDataSet.valueFont = UIFont(name: "Montserrat-Medium", size: 9)!
                reversedCarbsDataSet.valueFont = UIFont(name: "Montserrat-Medium", size: 9)!
                reversedFatDataSet.valueFont = UIFont(name: "Montserrat-Medium", size: 9)!
                chartData = BarChartData(dataSets: chartDataSets)
            }
            else {
                cell.barChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: VC?.monthChartLabels ?? ["1", "2", "3", "4", "5"])
                cell.barChart.xAxis.axisMaximum = Double(proteinChartDataSet.count)
                let chartDataSets = [proteinChartDataSet, carbsChartDataSet, fatChartDataSet]
                proteinChartDataSet.colors = [Color.mint]
                carbsChartDataSet.colors = [Color.skyBlue]
                fatChartDataSet.colors = [Color.salmon]
                proteinChartDataSet.valueFont = UIFont(name: "Montserrat-Medium", size: 9)!
                carbsChartDataSet.valueFont = UIFont(name: "Montserrat-Medium", size: 9)!
                fatChartDataSet.valueFont = UIFont(name: "Montserrat-Medium", size: 9)!
                chartData = BarChartData(dataSets: chartDataSets)
                
            }
            chartData.setValueFormatter(XValueFormatter())
            chartData.barWidth = 0.23
            chartData.groupBars(fromX: 0, groupSpace: 0.16, barSpace: 0.05)
            cell.barChart.animate(yAxisDuration: 0.5)
            cell.barChart.data = chartData
            
            var averageProtein = 0.0
            var averageCarbs = 0.0
            var averageFat = 0.0
            
            averageProtein = getAverageValueOfNutrient(entries: proteinChartDataSet.entries, nutrient: averageProtein)
            averageCarbs = getAverageValueOfNutrient(entries: carbsChartDataSet.entries, nutrient: averageCarbs)
            averageFat = getAverageValueOfNutrient(entries: fatChartDataSet.entries, nutrient: averageFat)
            
            cell.proteinLabel.text = averageProtein.removePointZeroEndingAndConvertToString() + " g"
            cell.carbsLabel.text = averageCarbs.removePointZeroEndingAndConvertToString() + " g"
            cell.fatLabel.text = averageFat.removePointZeroEndingAndConvertToString() + " g"
            
            
            return cell
        }
        else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LineChartCell", for: indexPath) as! LineChartCell
            
            let VC = parent as? NutritionViewController
            let defaults = UserDefaults()
            
            cell.lineChart.xAxis.granularityEnabled = true
            cell.lineChart.xAxis.axisMaximum = 3.5
            
            cell.lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: VC?.monthChartLabels.reversed() ?? ["1", "2", "3", "4", "5"])

            if direction == .backward {
                let reversedCalorieDataSet = LineChartDataSet(entries: [ChartDataEntry(x: 0, y: 0)], label: "Calories")
                _=reversedCalorieDataSet.remove(at: 0)
                for i in stride(from: lineChartDataSet.count - 1, through: 0, by: -1) {
                    reversedCalorieDataSet.append(lineChartDataSet[i])
                }
                var index = 0.0
                for value in reversedCalorieDataSet.entries {
                    value.x = index
                    index += 1
                }

                reversedCalorieDataSet.colors = [Color.skyBlue]
                reversedCalorieDataSet.circleColors = [Color.skyBlue]
                reversedCalorieDataSet.valueFont = UIFont(name: "Montserrat-SemiBold", size: 12)!
                
                let chartData = LineChartData(dataSet: reversedCalorieDataSet)
                cell.lineChart.data = chartData
            }
            else {
                cell.lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: VC?.monthChartLabels ?? ["1", "2", "3", "4", "5"])
                lineChartDataSet.colors = [Color.skyBlue]
                lineChartDataSet.circleColors = [Color.skyBlue]
                lineChartDataSet.valueFont = UIFont(name: "Montserrat-SemiBold", size: 12)!
                
                let chartData = LineChartData(dataSet: lineChartDataSet)
                cell.lineChart.data = chartData
            }
            cell.lineChart.animate(yAxisDuration: 0.5)
            var averageCalories = round(getAverageOfValue(dataSet: lineChartDataSet))
            
            if let goalCalories = (defaults.value(forKey: "GoalCalories") as? Int) {
                configureCalorieLabelColour(calories: Int(averageCalories), goalCalories: goalCalories, cell: cell)
                let limitLine = ChartLimitLine(limit: Double(goalCalories), label: "")
                limitLine.lineDashLengths = [8]
                limitLine.lineWidth = 1.5
                limitLine.lineColor = Color.mint
                limitLine.valueFont = UIFont(name: "Montserrat-Regular", size: 12)!
                
                cell.lineChart.leftAxis.addLimitLine(limitLine)
            }
            
            cell.caloriesLabel.text = averageCalories.removePointZeroEndingAndConvertToString()
            cell.goalValueLabel.text = "\(defaults.value(forKey: "GoalCalories") ?? 0)"
            
            return cell
        }
        
        return UITableViewCell()
    }
    
}
