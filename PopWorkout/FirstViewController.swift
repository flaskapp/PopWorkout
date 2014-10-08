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

    @IBAction func querySampleWorkout() {
        let distanceType = HKObjectType.quantityTypeForIdentifier( HKQuantityTypeIdentifierDistanceWalkingRunning)
        
        //let workout = HKWorkout(activityType: HKWorkoutActivityType.Running, startDate: nil, endDate: nil)
        
        let workoutPredicate = HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.Running)
        
        let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil,
            limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                

                if error != nil {
                    println("*** An error occurred while adding a sample to " +
                        "the workout: \(error.localizedDescription)")
                    
                    abort()
                }
                
                for samples in results {
                    println(samples)
                    let workout = samples as HKWorkout
                    println(workout.totalDistance)
                    println(workout.totalEnergyBurned)
                    
//                    for workout in samples as [AnyObject] {
//                        println(workout)
//                    }
                }
        }
        
        healthStore.executeQuery(query)
    }
    
    
    @IBAction func addSampleWorkout() {
        let start = NSDate()
        let end = NSDate()
        let intervals = [NSDate(), NSDate()]
        
        let energyBurned = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: 425.0)
        
        let distance = HKQuantity(unit: HKUnit.mileUnit(),
            doubleValue: 3.2)
        
        // Provide summary information when creating the workout.
        let run = HKWorkout(activityType: HKWorkoutActivityType.Running,
            startDate: start, endDate: end, duration: 0,
            totalEnergyBurned: energyBurned, totalDistance: distance, metadata: nil)
        
        // Save the workout before adding detailed samples.
        healthStore.saveObject(run) { (success, error) -> Void in
            if !success {
                // Perform proper error handling here...
                println("*** An error occurred while saving the " +
                    "workout: \(error.localizedDescription)")
                
                abort()
            }
            
            // Add optional, detailed information for each time interval
            var samples: [HKQuantitySample] = []
            
            let distanceType =
            HKObjectType.quantityTypeForIdentifier(
                HKQuantityTypeIdentifierDistanceWalkingRunning)
            
            let distancePerInterval = HKQuantity(unit: HKUnit.footUnit(),
                doubleValue: 165.0)
            
            let distancePerIntervalSample =
            HKQuantitySample(type: distanceType, quantity: distancePerInterval,
                startDate: intervals[0], endDate: intervals[1])
            
            samples.append(distancePerIntervalSample)
            
            let energyBurnedType =
            HKObjectType.quantityTypeForIdentifier(
                HKQuantityTypeIdentifierActiveEnergyBurned)
            
            let energyBurnedPerInterval = HKQuantity(unit: HKUnit.kilocalorieUnit(),
                doubleValue: 15.5)
            
            let energyBurnedPerIntervalSample =
            HKQuantitySample(type: energyBurnedType, quantity: energyBurnedPerInterval,
                startDate: intervals[0], endDate: intervals[1])
            
            samples.append(energyBurnedPerIntervalSample)
            
//            let heartRateType =
//            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
//            
//            let heartRateForInterval = HKQuantity(unit: HKUnit(fromString: "count/min"),
//                doubleValue: 95.0)
//            
//            let heartRateForIntervalSample =
//            HKQuantitySample(type: heartRateType, quantity: heartRateForInterval,
//                startDate: intervals[0], endDate: intervals[1])
//            
//            samples.append(heartRateForIntervalSample)
//            
            // Continue adding detailed samples...
            
            // Add all the samples to the workout.
            self.healthStore.addSamples(samples,
                toWorkout: run) { (success, error) -> Void in
                    if !success {
                        // Perform proper error handling here...
                        println("*** An error occurred while adding a " +
                            "sample to the workout: \(error.localizedDescription)")
                        abort()
                    }
            }
        }
    }
}

