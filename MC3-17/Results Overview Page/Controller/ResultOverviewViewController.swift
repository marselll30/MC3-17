//
//  ResultOverviewViewController.swift
//  MC3-17
//
//  Created by Sherwin Yang on 27/07/20.
//  Copyright © 2020 Sherwin Yang. All rights reserved.
//

import UIKit

class ResultOverviewViewController: UIViewController {
    
    @IBOutlet var moveCategorySegmentedControl: UISegmentedControl!
    @IBOutlet var overviewTableView: UITableView!
    
    var moveCategories = [MoveCategory]()
    var goodMoves = [MoveCategory]()
    var badMoves = [MoveCategory]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.allocateGoodBadMoves()
    }
    
    func allocateGoodBadMoves() {
        for i in 0..<moveCategories.count {
            if moveCategories[i].shotQuality == ShotQuality.goodMove {
                goodMoves.append(moveCategories[i])
            }
            else if moveCategories[i].shotQuality == ShotQuality.badMove {
                badMoves.append(moveCategories[i])
            }
        }
    }
    
    @IBAction func moveCategorySegmentedIndexChanged(_ sender: Any) {
        self.overviewTableView.reloadData()
    }
    
//    func dummy() {
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.goodMove, time: 30))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.badMove, time: 50))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.goodMove, time: 230))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.goodMove, time: 250))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.badMove, time: 300))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.goodMove, time: 430))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.goodMove, time: 550))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.badMove, time: 610))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.goodMove, time: 640))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.goodMove, time: 1000))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.goodMove, time: 3800))
//        moveCategories.append(MoveCategory(shotQuality: ShotQuality.badMove, time: 4600))
//    }
}

extension ResultOverviewViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if moveCategorySegmentedControl.selectedSegmentIndex == 0 {
            return self.badMoves.count
        }
        
        return self.goodMoves.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cells") as! ResultOverviewTableViewCell
        
        if moveCategorySegmentedControl.selectedSegmentIndex == 0 {
            cell.playImage.tintColor = UIColor(red: 228/256, green: 63/256, blue: 90/256, alpha: 1)
            cell.timeLabel.text = "\(badMoves[indexPath.row].time/3600):\(badMoves[indexPath.row].time%3600/60):\(badMoves[indexPath.row].time%3600%60)"
        }
        else if moveCategorySegmentedControl.selectedSegmentIndex == 1 {
            cell.playImage.tintColor = UIColor(red: 63/256, green: 228/256, blue: 98/256, alpha: 1)
            cell.timeLabel.text = "\(goodMoves[indexPath.row].time/3600):\(goodMoves[indexPath.row].time%3600/60):\(goodMoves[indexPath.row].time%3600%60)"
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
