//
//  PLWEntryViewController.swift
//  PopWorkout
//
//  Created by ogawa on 2014/10/07.
//  Copyright (c) 2014年 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class PLWEntryViewController: UITableViewController {
    @IBOutlet var typeLabel:UILabel!
    @IBOutlet var startLabel:UILabel!
    @IBOutlet var endLabel:UILabel!
    @IBOutlet var distanceText:UITextField!
    @IBOutlet var burnedText:UITextField!

    let healthStore:HKHealthStore = HKHealthStore()
    var selectedType:HKWorkoutActivityType = HKWorkoutActivityType.Walking
    var start:NSDate?
    var end:NSDate?
    var distance:Double = 0
    var burnedCalories:Double = 0
    
    override func loadView() {
        super.loadView()
        
        let cal:NSCalendar = NSCalendar.currentCalendar()
        let comps:NSDateComponents = cal.components(NSCalendarUnit.YearCalendarUnit | NSCalendarUnit.MonthCalendarUnit | NSCalendarUnit.DayCalendarUnit | NSCalendarUnit.HourCalendarUnit, fromDate: NSDate())
        end = cal.dateFromComponents(comps)
        comps.hour--
        start = cal.dateFromComponents(comps)
        self._updateUI()
        self.requestPrivacy()
    }
    
    func requestPrivacy() {
        let distanceType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
        let energyBurnedType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
        let workoutType = HKWorkoutType.workoutType()
        
        let types:NSSet = NSSet(objects: distanceType, energyBurnedType, workoutType)
        healthStore.requestAuthorizationToShareTypes(types, readTypes: types) { (success, error) -> Void in
            if success {
                println("success")
            } else {
                println(error)
            }
        }
    }
    
    
    func _updateUI() {
        typeLabel.text = self._stringOfWorkoutType(selectedType)
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = NSDateFormatterStyle.MediumStyle
        
        if start != nil {
            startLabel.text = formatter.stringFromDate(start!)
        } else {
            startLabel.text = ""
        }
        
        if end != nil {
            endLabel.text = formatter.stringFromDate(end!)
        } else {
            endLabel.text = ""
        }
        
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 0
        distanceText.text = numberFormatter.stringFromNumber(NSNumber(double: distance))
        burnedText.text = numberFormatter.stringFromNumber(NSNumber(double: burnedCalories))
        
       self._resignTexts()
    }
    
    func _resignTexts() {
        distanceText.resignFirstResponder()
        burnedText.resignFirstResponder()
    }
    
    func _chooseType() {
        self._resignTexts()
        var sheet = UIAlertController(title:nil, message: nil, preferredStyle: .ActionSheet)
        let types:[HKWorkoutActivityType] = [HKWorkoutActivityType.Walking, HKWorkoutActivityType.Running, HKWorkoutActivityType.Cycling, HKWorkoutActivityType.MixedMetabolicCardioTraining, HKWorkoutActivityType.Swimming];
    
        for type in types {
            let action = UIAlertAction(title: self._stringOfWorkoutType(type), style: .Default, handler: { (action) -> Void in
                self.selectedType = type
                self._updateUI()
            })
            sheet.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) {
            action in //nohitng todo
        }
        sheet.addAction(cancelAction)
        presentViewController(sheet, animated: true, completion: nil)
    }
    
    func _chooseStart() {
        self._resignTexts()
        PLWDatePickerViewController.show(self, date: start) { (selectedDate) -> () in
            self.start = selectedDate
            self._updateUI()
        }
    }
    
    func _chooseEnd() {
        self._resignTexts()
        PLWDatePickerViewController.show(self, date: end) { (selectedDate) -> () in
            self.end = selectedDate
            self._updateUI()
        }
    }
    
    func _save() {
        self._resignTexts()
        let formatter = NSNumberFormatter()
        let burned = formatter.numberFromString(burnedText.text)!.doubleValue
        let energyBurned = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: burned)
        let dis = formatter.numberFromString(distanceText.text)!.doubleValue
        let distance = HKQuantity(unit: HKUnit.mileUnit(), doubleValue: dis)
        
        let workout = HKWorkout(activityType: self.selectedType,
            startDate: start, endDate: end, duration: 0,
            totalEnergyBurned: energyBurned, totalDistance: distance, metadata: nil)
        
        // Save the workout before adding detailed samples.
        healthStore.saveObject(workout) { (success, error) -> Void in
            if !success {
                self._showErrorDialog("*** An error occurred while saving the " +
                    "workout: \(error.localizedDescription)")
                //abort()
            }

            // Add optional, detailed information for each time interval
            var samples: [HKQuantitySample] = []
            
            if dis > 0 {
                let distanceType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)
                
                let distancePerInterval = HKQuantity(unit: HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Kilo),
                    doubleValue: dis)
                
                let distancePerIntervalSample = HKQuantitySample(type: distanceType, quantity: distancePerInterval,
                    startDate: self.start, endDate: self.end)
                
                samples.append(distancePerIntervalSample)
            }
            

            if burned > 0 {
                let energyBurnedType =
                HKObjectType.quantityTypeForIdentifier(
                    HKQuantityTypeIdentifierActiveEnergyBurned)
                
                let energyBurnedPerInterval = HKQuantity(unit: HKUnit.kilocalorieUnit(),
                    doubleValue: burned)
                
                let energyBurnedPerIntervalSample =
                HKQuantitySample(type: energyBurnedType, quantity: energyBurnedPerInterval,
                    startDate: self.start, endDate: self.end)
                
                samples.append(energyBurnedPerIntervalSample)
            }


            // Add all the samples to the workout.
            if samples.count > 0 {
                self.healthStore.addSamples(samples,
                    toWorkout: workout) { (success, error) -> Void in
                        if !success {
                            // Perform proper error handling here...
                            self._showErrorDialog("*** An error occurred while adding a " +
                                "sample to the workout: \(error.localizedDescription)")
                            //abort()
                        } else {
                            self._showErrorDialog("Saved!")
                        }
                }
            }
        }

    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            self._chooseType()
        } else if (indexPath.section == 1 && indexPath.row == 0) {
            self._chooseStart()
        } else if (indexPath.section == 1 && indexPath.row == 1) {
            self._chooseEnd()
        } else if (indexPath.section == 3 && indexPath.row == 0) {
            self._save();
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
    
    func _showErrorDialog(message:String) {
        var alertController = UIAlertController(
            title: "",
            message: message, preferredStyle: .Alert)
        let otherAction = UIAlertAction(title: "Close", style: .Default) {action in }
        alertController.addAction(otherAction)
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}
