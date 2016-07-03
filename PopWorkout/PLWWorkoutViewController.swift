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
    var datas:[PLWSampleDatas] = []
    var caloriesDatas:[HKQuantitySample] = []
    var distanceDatas:[HKQuantitySample] = []
    
    enum WorkoutInfo:Int {
        case metaData, events, datas
        func toString() -> String {
            switch (self) {
            case .metaData: return "Meta Data"
            case .events: return "Events"
            case .datas: return "Datas"
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        if let metadatas = workout.metadata {
            for obj in metadatas {
                print(obj.key, obj.value, NSStringFromClass(obj.value.dynamicType))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadDatas()
    }
    
    func reloadDatas() {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let startDateSort = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let healthStore:HKHealthStore = HKHealthStore()
        self.datas.removeAll()

        let queue = OperationQueue()
        for item in PLWHealthManager.sharedInstance.healthItems {
            queue.addOperation({
                let query = HKSampleQuery(sampleType: item.type, predicate: predicate, limit: 0, sortDescriptors: [startDateSort]) {
                    (sampleQuery, results, error) -> Void in
                    guard let samples = results as? [HKQuantitySample] else { return }
                    if samples.isEmpty { return }
                    let data = PLWSampleDatas(samples: samples, healthItem: item)
                    self.datas.append(data)
                    DispatchQueue.main.async(execute: {
                        self.tableView.reloadData()
                    })
                }
                healthStore.execute(query)
            })
        }
    }

    
    //MARK: UITableViewDataSource implements
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return WorkoutInfo(rawValue: section)?.toString()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == WorkoutInfo.metaData.rawValue {
            if let metadata = workout.metadata {
                return metadata.count
            } else {
                return 0
            }
        } else if section == WorkoutInfo.events.rawValue {
            if let data = workout.workoutEvents {
                return data.count
            } else {
                return 0
            }
        } else if section == WorkoutInfo.datas.rawValue {
            return datas.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == WorkoutInfo.metaData.rawValue {
            let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "MetaCell", for: indexPath)
            if let metadatas = workout.metadata {
                let keys = Array(metadatas.keys)
                let key:String = keys[indexPath.row]
                cell.textLabel?.text = key
                if let value = metadatas[key] {
                    cell.detailTextLabel?.text = "\(value)"
                } else {
                    cell.detailTextLabel?.text = ""
                }
            }
            return cell
        }
        
        if indexPath.section == WorkoutInfo.events.rawValue {
            let cell:FLWWorkoutEventTableCellView = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! FLWWorkoutEventTableCellView
            let event = workout.workoutEvents![indexPath.row]
            if event.type == .pause {
                cell.eventNameLabel.text = "Pause"
            } else if event.type == .resume {
                cell.eventNameLabel.text = "Resume"
            } else if event.type == .lap {
                cell.eventNameLabel.text = "Lap"
            } else if event.type == .marker {
                cell.eventNameLabel.text = "Marker"
            } else if event.type == .motionPaused {
                cell.eventNameLabel.text = "MotionPaused"
            } else if event.type == .motionResumed {
                cell.eventNameLabel.text = "MotionResumed"
            } else {
                cell.eventNameLabel.text = ""
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .mediumStyle
            dateFormatter.timeStyle = .mediumStyle
            cell.startDateLabel.text = dateFormatter.string(from: event.date)
            return cell
        }
        
        if indexPath.section == WorkoutInfo.datas.rawValue {
            let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "DataCell", for: indexPath)
            let data = datas[indexPath.row]
            cell.textLabel?.text = data.healthItem.displayName
            cell.detailTextLabel?.text = data.detail
            return cell
        }
        return tableView.dequeueReusableCell(withIdentifier: "MetaCell", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == WorkoutInfo.datas.rawValue {
            let data = datas[indexPath.row]
            let controller = storyboard?.instantiateViewController(withIdentifier: "WorkoutDatas") as! PLWWorkoutDatasViewController
            controller.data = data
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}
