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
    
    override func loadView() {
        super.loadView()
        self.reloadDatas()
    }
    
    @IBAction func reloadDatas() {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let startDateSort = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let healthStore:HKHealthStore = HKHealthStore()
        
        //Active Calories
        let calType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)
        let calquery = HKSampleQuery(sampleType: calType!, predicate: predicate,
            limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                
                if let e = error {
                    print("*** An error occurred while adding a sample to " +
                        "the workout: \(e.localizedDescription)")
                    abort()
                }
                self.caloriesDatas = results as! [HKQuantitySample]
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .automatic)
                })
        }
        healthStore.execute(calquery)
        
        //Distance
        let distanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
        let query = HKSampleQuery(sampleType: distanceType!, predicate: predicate, limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                
                if let e = error {
                    print("*** An error occurred while adding a sample to " +
                        "the workout: \(e.localizedDescription)")
                    abort()
                }
                self.distanceDatas = results as! [HKQuantitySample]
                DispatchQueue.main.async(execute: { 
                    self.tableView.reloadSections(NSIndexSet(index: 1) as IndexSet, with: .automatic)
                })
        }
        healthStore.execute(query)
    }
    
    //MARK: UITableViewDataSource implements
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Active Calories"
        } else if section == 1 {
            return "Distance"
        } else if section == 2 {
            return "Meta Data"
        } else if section == 3 {
            return "Events"
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return caloriesDatas.count
        } else if section == 1 {
            return distanceDatas.count
        } else if section == 2 {
            if let metadata = workout.metadata {
                return metadata.count
            } else {
                return 0
            }
        } else if section == 3 {
            if let data = workout.workoutEvents {
                return data.count
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 2 {
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
        
        if (indexPath as NSIndexPath).section == 3 {
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
        
        if (indexPath as NSIndexPath).section == 0 {
            quantity = caloriesDatas[(indexPath as NSIndexPath).row]
            unit = HKUnit.kilocalorie()
            
        } else if (indexPath as NSIndexPath).section == 1 {
            quantity = distanceDatas[(indexPath as NSIndexPath).row]
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
            
            let value = quantity.quantity.doubleValue(for: unit!)
            cell.valueLabel.text = numberFormatter.string(from: NSNumber(value: value))! + unit.unitString
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section > 1 {
            return
        }
        var quantity:HKQuantitySample!
        if indexPath.section == 0 {
            quantity = caloriesDatas[(indexPath as NSIndexPath).row]
        } else if indexPath.section == 1 {
            quantity = distanceDatas[(indexPath as NSIndexPath).row]
        } else {
            return
        }
        
        let healthStore:HKHealthStore = HKHealthStore()
        healthStore.delete(quantity, withCompletion: { (success, error) -> Void in
            if success {
                if indexPath.section == 0 {
                    self.caloriesDatas.remove(at: (indexPath as NSIndexPath).row)
                } else if indexPath.section == 1 {
                    self.distanceDatas.remove(at: (indexPath as NSIndexPath).row)
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
        if (indexPath as NSIndexPath).section < 2 {
            return .delete
        } else {
            return .none
        }
    }
}
