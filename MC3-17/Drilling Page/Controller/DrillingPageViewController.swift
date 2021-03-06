//
//  DrillingPageViewController.swift
//  MC3-17
//
//  Created by Diana Ambarwati Febriani on 28/07/20.
//  Copyright © 2020 Sherwin Yang. All rights reserved.
//

import UIKit
import WatchConnectivity
import CoreML

class DrillingPageViewController: UIViewController {
    @IBOutlet weak var hoursText: UILabel!
    @IBOutlet weak var minuteText: UILabel!
    @IBOutlet weak var secondsText: UILabel!
    
    var results: Result!
    var drillDetails = [DrillDetail]()
    
    let accX = try? MLMultiArray(
        shape: [MlParameters.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    
    let accY = try? MLMultiArray(
        shape: [MlParameters.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    
    let accZ = try? MLMultiArray(
        shape: [MlParameters.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    
    let rotX = try? MLMultiArray(
        shape: [MlParameters.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    
    let rotY = try? MLMultiArray(
        shape: [MlParameters.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    
    let rotZ = try? MLMultiArray(
        shape: [MlParameters.predictionWindowSize] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    
    var currentState = try? MLMultiArray(
        shape: [MlParameters.stateInLength as NSNumber],
        dataType: MLMultiArrayDataType.double)
    
    private let classifier = BadmintonActivityClassifier()
    private let modelName:String = "BadmintonActivityClassifier"
    var currentIndexInPredictionWindow = 0
    var wcSession : WCSession! = nil
    
    var hours = 0
    var minutes = 0
    var seconds = 0
    
    var timer = Timer()
    var permissionHelper = PermissionHelper()
    var isHealthStoreAuthorized = false
    var isRun = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        
        permissionHelper.delegate = self
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(count), userInfo: nil, repeats: true)
        
        print(navigationController?.viewControllers.count)
        
        checkHealthStoreAuth()
    }
    
    @objc func count() {
        if isHealthStoreAuthorized && isRun {
            seconds += 1
            if seconds == 60 {
                minutes += 1
                seconds = 0
                
            } else if minutes == 60 {
                hours += 1
                minutes = 0
                seconds = 0
            }
            
            //Show Timer Text
            if seconds < 10 {
                secondsText.text = "0\(seconds)"
            } else {
                secondsText.text = "\(seconds)"
            }
            
            if minutes < 10 {
                minuteText.text = "0\(minutes)"
            } else {
                minuteText.text = "\(minutes)"
            }
            
            if hours < 10 {
                hoursText.text = "0\(hours)"
            } else {
                hoursText.text = "\(hours)"
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        results = Result(drillDetail: drillDetails)
        let drillResult = Drill(drill_name: SharedInfo.selectedDrill, video: nil, drill_details: drillDetails)
        DataModel.addNewData(drill: drillResult)
        if let identifer = segue.identifier {
            if identifer == SegueIdentifier.toResultsNoVideo {
                if let destination = segue.destination as? ResultNoVideoVC {
                    destination.results = results
                    destination.duration = "\(hours):\(minutes):\(seconds)"
                }
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

//MARK: - PermissionHelperDelegate
extension DrillingPageViewController: PermissionHelperDelegate {
    func didSuccessHealthStoreAuth() {
        checkHealthStoreAuth()
    }
    
    func didFailHealthStoreAuth() {
        
    }
    
    func checkHealthStoreAuth(){
        switch permissionHelper.getHealthStoreAuthStatus() {
        case 0:
            print("notDetermined")
            permissionHelper.requestHealthStoreAuth()
            break
        case 1:
            print("sharingDenied")
            isHealthStoreAuthorized = false
            //do something here
            break
        case 2:
            print("sharingAuthorized")
            isHealthStoreAuthorized = true
            break
        default:
            permissionHelper.requestHealthStoreAuth()
        }
    }
}

//MARK: - WatchConnectivity
extension DrillingPageViewController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let instruction = message["instructionFromWatch"] as? String {
            print("INSTRUCTION1: \(instruction)")
            if instruction == "START" {
                self.isRun = true
            } else if instruction == "STOP" {
                self.isRun = false
                // Go to result page
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: SegueIdentifier.toResultsNoVideo, sender: self)
                }
            }
        }
        
        if let csv = message["motionFromWatch"] as? String {
            print(csv)
            //            csvString = csvString.appending(csv)
            convertCsvStrToArray(csvStr: csv)
        }
        
    }
    
//    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
//        if let instruction = message["instructionFromWatch"] as? String {
//            print("INSTRUCTION2: \(instruction)")
//        }
//    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func sendMessage(strMsg: String, isPreditionData: Bool){
        var message = ["instructionFromIos":strMsg]
        if isPreditionData {
            message = ["preditionFromIos":strMsg]
        }
        
        wcSession.sendMessage(message, replyHandler: nil) { (error) in
            
            print(error.localizedDescription)
            
        }
    }
    
    private func isReachable() -> Bool {
        return wcSession.isReachable
    }
}

//MARK: - CoreML
extension DrillingPageViewController {
    func activityPrediction() -> String? {
        // Perform prediction
        let modelPrediction = try? classifier.prediction(
            Accelerometer_X: accX!,
            Accelerometer_Y: accY!,
            Accelerometer_Z: accZ!,
            Gyroscope_X: rotX!,
            Gyroscope_Y: rotY!,
            Gyroscope_Z: rotZ!,
            stateIn: currentState)
        
        // Update the state vector
        currentState = modelPrediction?.stateOut
        
        // Return the predicted activity
        return modelPrediction?.label
    }
    
    func convertCsvStrToArray(csvStr: String) {
        DispatchQueue.global().async {
            let lines = csvStr.split(separator: "\n")
            for line in lines {
                let columns = line.split(separator: ",", omittingEmptySubsequences: false)
                self.accX![self.currentIndexInPredictionWindow] = Double(columns[0])! as NSNumber
                self.accY![self.currentIndexInPredictionWindow] = Double(columns[1])! as NSNumber
                self.accZ![self.currentIndexInPredictionWindow] = Double(columns[2])! as NSNumber
                self.rotX![self.currentIndexInPredictionWindow] = Double(columns[3])! as NSNumber
                self.rotY![self.currentIndexInPredictionWindow] = Double(columns[4])! as NSNumber
                self.rotZ![self.currentIndexInPredictionWindow] = Double(columns[5])! as NSNumber
                
                // Update prediction array index
                self.currentIndexInPredictionWindow += 1
                
                // If data array is full - execute a prediction
                if (self.currentIndexInPredictionWindow == MlParameters.predictionWindowSize) {
                    // Move to main thread to update the UI
                    DispatchQueue.main.async {
                        if let predictionResult = self.activityPrediction() {
                            print("PREDICTION: \(predictionResult)")
                            if predictionResult == "lob_betul" {
                                self.drillDetails.append(DrillDetail(shotQuality: ShotQuality.goodMove, time: 0)) // need time sended from watch
                            }
                            else if predictionResult == "lob_salah" {
                                self.drillDetails.append(DrillDetail(shotQuality: ShotQuality.badMove, time: 0)) // need time sended from watch
                            }
                            
                            self.sendMessage(strMsg: predictionResult, isPreditionData: true)
                        }
                    }
                    // Start a new prediction window from scratch
                    self.currentIndexInPredictionWindow = 0
                }
            }
        }
    }
}
