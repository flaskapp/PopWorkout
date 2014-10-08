//
//  PLWListViewController.swift
//  PopWorkout
//
//  Created by ogawa on 2014/10/07.
//  Copyright (c) 2014年 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class PLWListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
   @IBOutlet var tableView:UITableView!
    
    var datas:[HKWorkout] = []
    
    override func loadView() {
        super.loadView()
        self.reloadDatas()
    }
    
    @IBAction func reloadDatas() {
        //let workoutPredicate = HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.Running)
        
        let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil,
            limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                
                if error != nil {
                    println("*** An error occurred while adding a sample to " +
                        "the workout: \(error.localizedDescription)")
                    abort()
                }
                
                self.datas = results as [HKWorkout]
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
        }
        let healthStore:HKHealthStore = HKHealthStore()
        healthStore.executeQuery(query)
    }
    
    //MARK: UITableViewDataSource implements
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:FLWWorkoutTableCellView = tableView.dequeueReusableCellWithIdentifier("WorkoutCell", forIndexPath: indexPath) as FLWWorkoutTableCellView
        let workout:HKWorkout = datas[indexPath.row]
        
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 0
        
        let energyFormatter = NSEnergyFormatter()
        let totalEnergyBurned = workout.totalEnergyBurned.doubleValueForUnit(HKUnit.kilocalorieUnit())
        cell.burnedLabel.text = numberFormatter.stringFromNumber(NSNumber(double: totalEnergyBurned)) + "kcal"

        let totalDistance = workout.totalDistance.doubleValueForUnit(HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Kilo))
        cell.distanceLabel.text = numberFormatter.stringFromNumber(NSNumber(double: totalDistance)) + "km"
        
        let durationFormatter = NSDateComponentsFormatter()
        durationFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Abbreviated
        cell.durationLabel.text = durationFormatter.stringFromTimeInterval(workout.duration)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        cell.startLabel.text = dateFormatter.stringFromDate(workout.startDate)
        cell.endLabel.text = dateFormatter.stringFromDate(workout.endDate)
        
        cell.typeLabel.text = self._stringOfWorkoutType(workout.workoutActivityType)
        cell.sourceLabel.text = workout.source.name
        return cell
    }
    
    //MARK: UITableViewDelegate implements
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let workout:HKWorkout = datas[indexPath.row]
        let controller:PLWWorkoutViewController = self.storyboard!.instantiateViewControllerWithIdentifier("WorkoutViewController") as PLWWorkoutViewController
        controller.workout = workout
        self.navigationController!.pushViewController(controller, animated: true)

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let workout:HKWorkout = datas[indexPath.row]
        let healthStore:HKHealthStore = HKHealthStore()
        healthStore.deleteObject(workout, withCompletion: { (success, error) -> Void in
            if success {
                self.datas.removeAtIndex(indexPath.row)
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
        return UITableViewCellEditingStyle.Delete
    }
    
    func _stringOfWorkoutType(type:HKWorkoutActivityType) -> String {
        switch type {
        case HKWorkoutActivityType.Running:
            return "Running"
        case HKWorkoutActivityType.Walking:
            return "Walking"
        case HKWorkoutActivityType.MixedMetabolicCardioTraining:
            return "MixedMetabolicCardioTraining"
        case HKWorkoutActivityType.Swimming:
            return "Swimming"
        case HKWorkoutActivityType.Cycling:
            return "Cycling"
        default:
            return "\(type.hashValue)"
        }
    }
}
