//
//  PLWSampleDatas.swift
//  PopWorkout
//
//  Created by Hideko Ogawa on 7/3/16.
//  Copyright © 2016 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class PLWSampleDatas: NSObject {
    let healthItem:PLWHealthData
    var samples:[HKQuantitySample]
    let detail:String
    
    init(samples:[HKQuantitySample], healthItem:PLWHealthData) {
        self.samples = samples
        self.healthItem = healthItem
        
        var sum:Double = 0
        for sample in samples {
            sum += sample.quantity.doubleValue(for: healthItem.unit)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 5
        switch (healthItem.type.aggregationStyle) {
        case .cumulative:
            detail = formatter.string(from: sum)! + " " + healthItem.unit.unitString
            return
        case .discrete:
            if samples.count > 0 {
                let avg = sum / (Double) (samples.count)
                detail = formatter.string(from: avg)! + " " + healthItem.unit.unitString
            } else {
                detail = ""
            }
        }
    }
}
