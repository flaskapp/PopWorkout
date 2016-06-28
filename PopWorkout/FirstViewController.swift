//
//  FirstViewController.swift
//  PopWorkout
//
//  Created by ogawa on 2014/10/07.
//  Copyright (c) 2014年 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class FirstViewController: UIViewController {
    let healthStore:HKHealthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.requestPrivacy();

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func requestPrivacy() {
        
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

    @IBAction func querySampleWorkout() {
        let startDateSort = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil,
            limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                
                if let e = error {
                    print("*** An error occurred while adding a sample to " +
                        "the workout: \(e.localizedDescription)")
                }
                
                for samples in results! {
                    print(samples)
                    let workout = samples as! HKWorkout
                    print(workout.totalDistance)
                    print(workout.totalEnergyBurned)
                }
        }
        healthStore.execute(query)
    }
    
    
    @IBAction func addSampleWorkout() {
        let start = Date()
        let end = Date()
        let intervals = [Date(), Date()]
        
        let energyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 425.0)
        let distance = HKQuantity(unit: HKUnit.mile(), doubleValue: 3.2)
        
        // Provide summary information when creating the workout.
        let run = HKWorkout(activityType: HKWorkoutActivityType.running,
            start: start, end: end, duration: 0,
            totalEnergyBurned: energyBurned, totalDistance: distance, metadata: nil)

        healthStore.save(run) { (success, error) -> Void in
            if !success {
                // Perform proper error handling here...
                print("*** An error occurred while saving the " +
                    "workout: \(error?.localizedDescription)")
                
                abort()
            }
            
            // Add optional, detailed information for each time interval
            var samples: [HKQuantitySample] = []

            let distanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
            let distancePerInterval = HKQuantity(unit: HKUnit.foot(), doubleValue: 165.0)
            let distancePerIntervalSample = HKQuantitySample(type: distanceType, quantity: distancePerInterval, start: intervals[0], end: intervals[1])
            samples.append(distancePerIntervalSample)
            
            let energyBurnedType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
            let energyBurnedPerInterval = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 15.5)
            let energyBurnedPerIntervalSample = HKQuantitySample(type: energyBurnedType, quantity: energyBurnedPerInterval, start: intervals[0], end: intervals[1])
            samples.append(energyBurnedPerIntervalSample)
            
            // Add all the samples to the workout.
            self.healthStore.add(samples,
                to: run) { (success, error) -> Void in
                    if !success {
                        // Perform proper error handling here...
                        print("*** An error occurred while adding a " +
                            "sample to the workout: \(error?.localizedDescription)")
                        abort()
                    }
            }
        }
    }
}

