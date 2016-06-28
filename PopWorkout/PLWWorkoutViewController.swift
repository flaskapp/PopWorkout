//
//  PLWWorkoutViewController.swift
//  PopWorkout
//
//  Created by ogawa on 2014/10/08.
//  Copyright (c) 2014年 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class PLWWorkoutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView:UITableView!
    var workout:HKWorkout!
    var caloriesDatas:[HKQuantitySample] = []
    var distanceDatas:[HKQuantitySample] = []
    
    enum WorkoutInfo:Int {
        case metaData, events, activeCalories, distance
        func toString() -> String {
            switch (self) {
            case .metaData: return "Meta Data"
            case .events: return "Events"
            case .activeCalories: return "Active Calories"
            case .distance: return "Distance"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadDatas()
    }
    
    @IBAction func reloadDatas() {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let startDateSort = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let healthStore:HKHealthStore = HKHealthStore()
        
        //Active Calories
        let calType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        let calquery = HKSampleQuery(sampleType: calType, predicate: predicate,limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                if let e = error {
                    print("*** An error occurred while adding a sample to " + "the workout: \(e.localizedDescription)")
                    abort()
                }
                self.caloriesDatas = results as! [HKQuantitySample]
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                    //self.tableView.reloadSections(NSIndexSet(index: WorkoutInfo.activeCalories.rawValue) as IndexSet, with: .automatic)
                })
        }
        healthStore.execute(calquery)
        
        //Distance
        let distanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
        let query = HKSampleQuery(sampleType: distanceType, predicate: predicate, limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                if let e = error {
                    print("*** An error occurred while adding a sample to " + "the workout: \(e.localizedDescription)")
                    abort()
                }
                self.distanceDatas = results as! [HKQuantitySample]
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                    //self.tableView.reloadSections(NSIndexSet(index: WorkoutInfo.distance.rawValue) as IndexSet, with: .automatic)
                })
        }
        healthStore.execute(query)
        
        
        if let metadatas = workout.metadata {
            for obj in metadatas {
                print(obj.key, obj.value, NSStringFromClass(obj.value.dynamicType))
            }
        }
    }
    
    //MARK: UITableViewDataSource implements
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return WorkoutInfo(rawValue: section)?.toString()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == WorkoutInfo.metaData.rawValue {
            if let metadata = workout.metadata {
                return metadata.count
            } else {
                return 0
            }
        } else if section == WorkoutInfo.events.rawValue {
            if let data = workout.workoutEvents {
                return data.count
            } else {
                return 0
            }
        } else if section == WorkoutInfo.activeCalories.rawValue {
            return caloriesDatas.count
        } else if section == WorkoutInfo.distance.rawValue {
            return distanceDatas.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == WorkoutInfo.metaData.rawValue {
            let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "MetaCell", for: indexPath)
            if let metadatas = workout.metadata {
                let keys = Array(metadatas.keys)
                let key:String = keys[indexPath.row]
                cell.textLabel?.text = key
                if let value = metadatas[key] {
                    cell.detailTextLabel?.text = "\(value)"
                } else {
                    cell.detailTextLabel?.text = ""
                }
            }
            return cell
        }
        
        if indexPath.section == WorkoutInfo.events.rawValue {
            let cell:FLWWorkoutEventTableCellView = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! FLWWorkoutEventTableCellView
            let event = workout.workoutEvents![indexPath.row]
            if event.type == .pause {
                cell.eventNameLabel.text = "Pause"
            } else if event.type == .resume {
                cell.eventNameLabel.text = "Resume"
            } else {
                cell.eventNameLabel.text = ""
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .mediumStyle
            dateFormatter.timeStyle = .mediumStyle
            cell.startDateLabel.text = dateFormatter.string(from: event.date)
            return cell
        }
        
        let cell:FLWQuantityTableCellView = tableView.dequeueReusableCell(withIdentifier: "QuantityCell", for: indexPath) as! FLWQuantityTableCellView
        var quantity:HKQuantitySample!
        var unit:HKUnit!
        
        if indexPath.section == WorkoutInfo.activeCalories.rawValue {
            quantity = caloriesDatas[indexPath.row]
            unit = HKUnit.kilocalorie()
            
        } else if indexPath.section == WorkoutInfo.distance.rawValue {
            quantity = distanceDatas[indexPath.row]
            unit = HKUnit.meterUnit(with: HKMetricPrefix.kilo)
        }
        
        if quantity != nil {
            cell.sourceLabel.text = quantity.source.name
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .mediumStyle
            dateFormatter.timeStyle = .mediumStyle
            cell.dateLabel.text = dateFormatter.string(from: quantity.startDate)
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.minimumFractionDigits = 0
            numberFormatter.maximumFractionDigits = 2
            
            let value = quantity.quantity.doubleValue(for: unit)
            cell.valueLabel.text = numberFormatter.string(from: NSNumber(value: value))! + unit.unitString
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        var quantity:HKQuantitySample!
        if indexPath.section == WorkoutInfo.activeCalories.rawValue {
            quantity = caloriesDatas[indexPath.row]
        } else if indexPath.section == WorkoutInfo.distance.rawValue {
            quantity = distanceDatas[indexPath.row]
        } else {
            return
        }
        
        let healthStore:HKHealthStore = HKHealthStore()
        healthStore.delete(quantity, withCompletion: { (success, error) -> Void in
            if success {
                if indexPath.section == WorkoutInfo.activeCalories.rawValue {
                    self.caloriesDatas.remove(at: indexPath.row)
                } else if indexPath.section == WorkoutInfo.distance.rawValue {
                    self.distanceDatas.remove(at: indexPath.row)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                let alertController = UIAlertController(
                    title: "削除エラー",
                    message: "削除失敗しました", preferredStyle: .alert)
                let otherAction = UIAlertAction(title: "閉じる", style: .default) {action in }
                alertController.addAction(otherAction)
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == WorkoutInfo.activeCalories.rawValue || indexPath.section == WorkoutInfo.distance.rawValue {
            return .delete
        } else {
            return .none
        }
    }
}
