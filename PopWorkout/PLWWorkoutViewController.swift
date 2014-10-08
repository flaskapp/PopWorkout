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
        let predicate = HKQuery.predicateForObjectsFromWorkout(workout)
        let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let healthStore:HKHealthStore = HKHealthStore()
        
        //Active Calories
        let calType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
        let calquery = HKSampleQuery(sampleType: calType, predicate: predicate,
            limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                
                if error != nil {
                    println("*** An error occurred while adding a sample to " +
                        "the workout: \(error.localizedDescription)")
                    abort()
                }
                self.caloriesDatas = results as [HKQuantitySample]
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                }
        }
        healthStore.executeQuery(calquery)
        
        //Distance
        let distanceType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
        let query = HKSampleQuery(sampleType: distanceType, predicate: predicate,
            limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                
                if error != nil {
                    println("*** An error occurred while adding a sample to " +
                        "the workout: \(error.localizedDescription)")
                    abort()
                }
                self.distanceDatas = results as [HKQuantitySample]
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: UITableViewRowAnimation.Automatic)
                }
        }
        healthStore.executeQuery(query)
    }
    
    //MARK: UITableViewDataSource implements
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Active Calories"
        } else if section == 1 {
            return "Distance"
        } else if section == 2 {
            return "Meta Data"
        }
        return ""
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return caloriesDatas.count
        } else if section == 1 {
            return distanceDatas.count
        } else if section == 2 {
            if workout.metadata == nil {
                return 0
            } else {
                return workout.metadata.count
            }
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 2 {
            let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("MetaCell", forIndexPath: indexPath) as UITableViewCell
            
            let key:String = workout.metadata.keys.array[indexPath.row] as String
            cell.textLabel?.text = key
            let value:AnyObject! = workout.metadata[key]
            cell.detailTextLabel?.text = "\(value)"
 
            return cell
        }
        
        let cell:FLWQuantityTableCellView = tableView.dequeueReusableCellWithIdentifier("QuantityCell", forIndexPath: indexPath) as FLWQuantityTableCellView
        
        var quantity:HKQuantitySample!
        var unit:HKUnit!
        
        if indexPath.section == 0 {
            quantity = caloriesDatas[indexPath.row]
            unit = HKUnit.kilocalorieUnit()
            
        } else if indexPath.section == 1 {
            quantity = distanceDatas[indexPath.row]
            unit = HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Kilo)
            
        }
        
        if quantity != nil {
            cell.sourceLabel.text = quantity.source.name
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
            cell.dateLabel.text = dateFormatter.stringFromDate(quantity.startDate)
            
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            numberFormatter.minimumFractionDigits = 2
            numberFormatter.maximumFractionDigits = 0
            
            let value = quantity.quantity.doubleValueForUnit(unit!)
            cell.valueLabel.text = numberFormatter.stringFromNumber(NSNumber(double: value)) + unit.unitString
        }
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section > 1 {
            return;
        }
        var quantity:HKQuantitySample!
        
        if indexPath.section == 0 {
            quantity = caloriesDatas[indexPath.row]
        } else if indexPath.section == 1 {
            quantity = distanceDatas[indexPath.row]
        } else {
            return
        }
        
        let healthStore:HKHealthStore = HKHealthStore()
        healthStore.deleteObject(quantity, withCompletion: { (success, error) -> Void in
            if success {
                if indexPath.section == 0 {
                    self.caloriesDatas.removeAtIndex(indexPath.row)
                } else if (indexPath.section == 1) {
                    self.distanceDatas.removeAtIndex(indexPath.row)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            } else {
                var alertController = UIAlertController(
                    title: "削除エラー",
                    message: "削除失敗しました", preferredStyle: .Alert)
                let otherAction = UIAlertAction(title: "閉じる", style: .Default) {action in }
                alertController.addAction(otherAction)
                dispatch_async(dispatch_get_main_queue()) {
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            }
        })
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section < 2 {
            return UITableViewCellEditingStyle.Delete
        } else {
            return UITableViewCellEditingStyle.None
        }
    }

}
