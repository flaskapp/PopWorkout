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
   @IBOutlet weak var tableView:UITableView!
    
    var datas:[HKWorkout] = []
    
    override func loadView() {
        super.loadView()
        self.reloadDatas()
    }
    
    @IBAction func reloadDatas() {
        let startDateSort = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil, limit: 0, sortDescriptors: [startDateSort]) {
                (sampleQuery, results, error) -> Void in
                
                if let e = error {
                    print("*** An error occurred while adding a sample to " +
                        "the workout: \(e.localizedDescription)")
                    abort()
                }
                
                if results != nil {
                    self.datas = results as! [HKWorkout]
                } else {
                    self.datas = []
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
        }
        let healthStore:HKHealthStore = HKHealthStore()
        healthStore.execute(query)
    }
    
    //MARK: UITableViewDataSource implements
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutCell", for: indexPath) as! FLWWorkoutTableCellView
        let workout:HKWorkout = datas[(indexPath as NSIndexPath).row]
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2

        if let burned = workout.totalEnergyBurned {
            let totalEnergyBurned = burned.doubleValue(for: HKUnit.kilocalorie())
            cell.burnedLabel.text = numberFormatter.string(from: NSNumber(value: totalEnergyBurned))! + "kcal"
        } else {
            cell.burnedLabel.text = ""
        }

        if let distance = workout.totalDistance {
            let totalDistance = distance.doubleValue(for: HKUnit.meterUnit(with: HKMetricPrefix.kilo))
            cell.distanceLabel.text = numberFormatter.string(from: NSNumber(value: totalDistance))! + "km"
        } else {
            cell.distanceLabel.text = ""
        }
        
        let durationFormatter = DateComponentsFormatter()
        durationFormatter.unitsStyle = .abbreviated
        cell.durationLabel.text = durationFormatter.string(from: workout.duration)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .mediumStyle
        dateFormatter.timeStyle = .mediumStyle
        cell.startLabel.text = dateFormatter.string(from: workout.startDate)
        cell.endLabel.text = dateFormatter.string(from: workout.endDate)
        
        cell.typeLabel.text = stringOfWorkoutType(workout.workoutActivityType)
        cell.sourceLabel.text = workout.sourceRevision.source.name
        return cell
    }
    
    //MARK: UITableViewDelegate implements
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let workout:HKWorkout = datas[(indexPath as NSIndexPath).row]
        let controller:PLWWorkoutViewController = self.storyboard!.instantiateViewController(withIdentifier: "WorkoutViewController") as! PLWWorkoutViewController
        controller.workout = workout
        self.navigationController!.pushViewController(controller, animated: true)

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let workout:HKWorkout = datas[(indexPath as NSIndexPath).row]
        let healthStore:HKHealthStore = HKHealthStore()
        healthStore.delete(workout, withCompletion: { (success, error) -> Void in
            if success {
                self.datas.remove(at: (indexPath as NSIndexPath).row)
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
        return UITableViewCellEditingStyle.delete
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
}
