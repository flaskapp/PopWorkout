//
//  PLWWorkoutDatasViewController.swift
//  PopWorkout
//
//  Created by ogawa on 2014/10/08.
//  Copyright (c) 2014年 Flask LLP. All rights reserved.
//

import UIKit
import HealthKit

class PLWWorkoutDatasViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView:UITableView!
    var data:PLWSampleDatas!
    
    override func loadView() {
        super.loadView()
        self.title = data.healthItem.displayName
    }

    //MARK: UITableViewDataSource implements
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.samples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuantityCell", for: indexPath) as! FLWQuantityTableCellView
        let sample:HKQuantitySample = data.samples[indexPath.row]
        cell.sourceLabel.text = sample.sourceRevision.source.name
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .mediumStyle
        dateFormatter.timeStyle = .mediumStyle
        cell.dateLabel.text = dateFormatter.string(from: sample.startDate)
        cell.valueLabel.text = data.healthItem.string(quantity: sample.quantity)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let sample:HKQuantitySample = data.samples[indexPath.row]
        let healthStore:HKHealthStore = HKHealthStore()
        healthStore.delete(sample, withCompletion: { (success, error) -> Void in
            if success {
                self.data.samples.remove(at: indexPath.row)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                print(error)
                let alertController = UIAlertController(
                    title: "Delete Error",
                    message: error?.localizedDescription, preferredStyle: .alert)
                let otherAction = UIAlertAction(title: "Close", style: .default) {action in }
                alertController.addAction(otherAction)
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
}
