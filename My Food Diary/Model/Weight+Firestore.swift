//
//  Weight+Firestore.swift
//  My Food Diary
//
//  Created by Daniel Hilton on 26/12/2019.
//  Copyright © 2019 Daniel Hilton. All rights reserved.
//

import Foundation
import Firebase

private let db = Firestore.firestore()

extension Weight {
    
    convenience init(snapshot: QueryDocumentSnapshot) {
        self.init()
        let foodDictionary = snapshot.data()
        self.weight = foodDictionary["weight"] as? Double ?? 0
        self.unit = foodDictionary["unit"] as? String ?? "kg"
        self.date = foodDictionary["date"] as? Date ?? Date()
        self.dateString = foodDictionary["dateString"] as? String
    }
    
    func saveFood(user: String) {
        
        db.collection("users").document(user).collection("weight").document("\(self.weight)").setData([
            "weight": self.weight,
            "unit": self.unit,
            "date": self.date,
            "dateString": self.dateString!
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added with ID: \(self.weight)")
            }
        }
    }
    
    static func downloadAllWeight(user: String, completion: @escaping ([Weight]) -> ()) {
        
        let calendar = Calendar.current
        let defaultDateComponents = DateComponents(calendar: calendar, timeZone: .current, year: 2019, month: 1, day: 1)
        var allWeight = [Weight]()
        var dateOfMostRecentEntry: Date?
        
        db.collection("users").document(user).collection("weight").order(by: "date").getDocuments(source: .cache) {
            (weight, error) in
            
            if let error = error {
                print("Error getting documents: \(error)")
            }
            else {
                for weightDocument in weight!.documents {
                    allWeight.append(Weight(snapshot: weightDocument))
                }
                dateOfMostRecentEntry = allWeight.last?.date
                
                db.collection("users").document(user).collection("weight")
                    .whereField("date", isGreaterThan: dateOfMostRecentEntry?.addingTimeInterval(1) ?? calendar.date(from: defaultDateComponents)!)
                    .order(by: "date")
                    .getDocuments() { (weight, error) in
                    if let error = error {
                        print("Error getting documents: \(error)")
                    }
                    else {
                        for weightDocument in weight!.documents {
                            allWeight.append(Weight(snapshot: weightDocument))
                            print(Weight(snapshot: weightDocument).weight)
                        }
                    }
                    completion(allWeight)
                }
                
            }
        }
        
        
        
    }
    
}
