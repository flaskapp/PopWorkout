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
    @IBOutlet weak var typeLabel:UILabel!
    @IBOutlet weak var startLabel:UILabel!
    @IBOutlet weak var endLabel:UILabel!
    @IBOutlet weak var distanceText:UITextField!
    @IBOutlet weak var burnedText:UITextField!

    let healthStore:HKHealthStore = HKHealthStore()
    var selectedType:HKWorkoutActivityType = .walking
    var start:Date!
    var end:Date!
    var distance:Double = 0
    var burnedCalories:Double = 0
    
    override func loadView() {
        super.loadView()
        let cal:Calendar = Calendar.current()
        var comps:DateComponents = cal.components([.year, .month, .day, .hour], from: Date())
        end = cal.date(from: comps)
        if let hour = comps.hour {
            comps.hour = hour - 1
        }
        start = cal.date(from: comps)
        self.updateUI()
        self.requestPrivacy()
    }
    
    private func requestPrivacy() {
        let distanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
        let energyBurnedType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        let workoutType = HKWorkoutType.workoutType()
        let types:Set<HKSampleType> = Set(arrayLiteral: distanceType, energyBurnedType, workoutType)
        healthStore.requestAuthorization(toShare: types, read: types) { (success, error) -> Void in
            if success {
                print("success")
            } else {
                print(error)
            }
        }
    }
    
    private func updateUI() {
        typeLabel.text = stringOfWorkoutType(selectedType)
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.mediumStyle
        formatter.timeStyle = DateFormatter.Style.mediumStyle
        startLabel.text = formatter.string(from: start)
        endLabel.text = formatter.string(from: end)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        distanceText.text = numberFormatter.string(from: NSNumber(value: distance))
        burnedText.text = numberFormatter.string(from: NSNumber(value: burnedCalories))
        
       self.resignTexts()
    }
    
    private func resignTexts() {
        distanceText.resignFirstResponder()
        burnedText.resignFirstResponder()
    }
    
    private func chooseType() {
        self.resignTexts()
        let sheet = UIAlertController(title:nil, message: nil, preferredStyle: .actionSheet)
        let types:[HKWorkoutActivityType] = [.walking, .running, .cycling, .mixedMetabolicCardioTraining, .swimming];
    
        for type in types {
            let action = UIAlertAction(title: stringOfWorkoutType(type), style: .default, handler: { (action) -> Void in
                self.selectedType = type
                self.updateUI()
            })
            sheet.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            action in //nohitng todo
        }
        sheet.addAction(cancelAction)
        present(sheet, animated: true, completion: nil)
    }
    
    func chooseStart() {
        self.resignTexts()
        //self.performSegue(withIdentifier: "ChooseDateTime", sender: nil)
        PLWDatePickerViewController.show(self, date: start) { (selectedDate) -> () in
            self.start = selectedDate
            self.updateUI()
        }
    }
    
    private func chooseEnd() {
        self.resignTexts()
        PLWDatePickerViewController.show(self, date: end) { (selectedDate) -> () in
            self.end = selectedDate
            self.updateUI()
        }
    }
    
    private func save() {
        self.resignTexts()
        let formatter = NumberFormatter()
        let burned = formatter.number(from: burnedText.text!)!.doubleValue
        let energyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: burned)
        let dis = formatter.number(from: distanceText.text!)!.doubleValue
        let distance = HKQuantity(unit: HKUnit.mile(), doubleValue: dis)
        let metadata:[String: AnyObject] = Dictionary()
//        let metadata = ["HKWeatherHumidity":HKQuantity(unit: HKUnit.percent(), doubleValue: 90),
//                        "HKWeatherTemperature":HKQuantity(unit: HKUnit.degreeCelsius(), doubleValue: 60)]
        
        let workout = HKWorkout(activityType: selectedType, start: start, end: end, duration: 0, totalEnergyBurned: energyBurned, totalDistance: distance, metadata: metadata)
        
        // Save the workout before adding detailed samples.
        healthStore.save(workout) { (success, error) -> Void in
            if !success {
                self.showErrorDialog("*** An error occurred while saving the " + "workout: \(error?.localizedDescription)")
            }

            // Add optional, detailed information for each time interval
            var samples: [HKQuantitySample] = []
            
            if dis > 0 {
                let distanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
                let distancePerInterval = HKQuantity(unit: HKUnit.meterUnit(with: HKMetricPrefix.kilo), doubleValue: dis)
                let distancePerIntervalSample = HKQuantitySample(type: distanceType, quantity: distancePerInterval, start: self.start, end: self.end)
                samples.append(distancePerIntervalSample)
            }

            if burned > 0 {
                let energyBurnedType = HKObjectType.quantityType( forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
                let energyBurnedPerInterval = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: burned)
                let energyBurnedPerIntervalSample = HKQuantitySample(type: energyBurnedType, quantity: energyBurnedPerInterval, start: self.start, end: self.end)
                samples.append(energyBurnedPerIntervalSample)
            }

            // Add all the samples to the workout.
            if samples.count > 0 {
                self.healthStore.add(samples, to: workout) { (success, error) -> Void in
                    if !success {
                        self.showErrorDialog("*** An error occurred while adding a " + "sample to the workout: \(error?.localizedDescription)")
                        //abort()
                    } else {
                        self.showErrorDialog("Saved!")
                    }
                }
            }
        }

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            chooseType()
        } else if indexPath.section == 1 && indexPath.row == 0 {
            chooseStart()
        } else if indexPath.section == 1 && indexPath.row == 1 {
            chooseEnd()
        } else if indexPath.section == 3 && indexPath.row == 0 {
            save()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func stringOfWorkoutType(_ type:HKWorkoutActivityType) -> String {
        switch type {
        case HKWorkoutActivityType.running:
            return "Running"
        case HKWorkoutActivityType.walking:
            return "Walking"
        case HKWorkoutActivityType.mixedMetabolicCardioTraining:
            return "MixedMetabolicCardioTraining"
        case HKWorkoutActivityType.swimming:
            return "Swimming"
        case HKWorkoutActivityType.cycling:
            return "Cycling"
        default:
            return "\(type.hashValue)"
        }
    }
    
    private func showErrorDialog(_ message:String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let otherAction = UIAlertAction(title: "Close", style: .default) {action in }
        alertController.addAction(otherAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
