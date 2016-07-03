//
//  PLWHealthData.swift
//  PopWorkout
//
//  Created by Hideko Ogawa on 7/3/16.
//  Copyright © 2016 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class PLWHealthData: NSObject {
    let type:HKQuantityType
    let unit:HKUnit
    var displayName:String
    
    init(type:HKQuantityType, unit:HKUnit, displayName:String) {
        self.type = type
        self.unit = unit
        self.displayName = displayName
    }
    
    func string(quantity:HKQuantity) -> String {
        let value = quantity.doubleValue(for: unit)
        return string(value: value)
    }
    
    func string(value:Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 5
        return numberFormatter.string(from: NSNumber(value: value))! + " " + unit.unitString
    }
}
