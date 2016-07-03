//
//  PLWHealthManager.swift
//  PopWorkout
//
//  Created by Hideko Ogawa on 7/3/16.
//  Copyright © 2016 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class PLWHealthManager: NSObject {
    static let sharedInstance = PLWHealthManager()
    let healthItems:[PLWHealthData]
    let distanceItem:PLWHealthData
    let energyBurnedItem:PLWHealthData
    let heartRateItem:PLWHealthData
    let basalBurnedItem:PLWHealthData

    private override init() {
        let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        distanceItem = PLWHealthData(type: distanceType, unit: HKUnit.meterUnit(with: .kilo), displayName: "Distance")
        let energyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        energyBurnedItem = PLWHealthData(type: energyBurnedType, unit: HKUnit.kilocalorie(), displayName: "Energy Burned")
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        heartRateItem = PLWHealthData(type: heartRateType, unit: HKUnit.count().unitDivided(by: HKUnit.minute()), displayName: "Heart Rate")
        let basalType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
        basalBurnedItem = PLWHealthData(type: basalType, unit: HKUnit.kilocalorie(), displayName: "Basal Burned")
        healthItems = [distanceItem, energyBurnedItem, heartRateItem, basalBurnedItem]
    }
    
    func requestPrivacy() {
        var types:Set<HKSampleType> = []
        for item in healthItems {
            types.insert(item.type)
        }
        types.insert(HKWorkoutType.workoutType())
        let healthStore = HKHealthStore()
        healthStore.requestAuthorization(toShare: types, read: types) { (success, error) -> Void in
            if success {
                print("success")
            } else {
                print(error)
            }
        }
    }
}
