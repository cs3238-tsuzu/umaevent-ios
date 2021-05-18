//
//  SampleHandler.swift
//  umascreen-uploader
//
//  Created by Tsuzu on 2021/05/16.
//

import ReplayKit
import CoreMedia
import CoreImage
import Alamofire
import UIKit

enum UploaderError: Error {
    case validation(msg: String)
}

struct Choice: Codable {
    let choice: String
    let effect: String
}

struct Result: Codable {
    let ok: Bool
    let eventName: String
    let choices: [Choice]
}

class SampleHandler: RPBroadcastSampleHandler, UNUserNotificationCenterDelegate {
    var ciContext: CIContext?
    let deviceRange = CropRangeStore.getRange(modelName: UIDevice.modelName)
    var lastTime: Double = 0
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        if deviceRange == nil {
            self.finishBroadcastWithError(UploaderError.validation(msg: "invalid device range"))
        }
        self.ciContext = CIContext.init()
        self.lastTime = Date().timeIntervalSince1970
        
        if #available(iOS 10.0, *) {
            // iOS 10
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { (granted, error) in
                if error != nil {
                    return
                }

                if granted {
                    print("通知許可")

                    let center = UNUserNotificationCenter.current()
                    center.delegate = self

                } else {
                    print("通知拒否")
                }
            })

        }
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            let current = Date().timeIntervalSince1970
            
            if current - lastTime < 0.5 {
                return
            }
            lastTime = current
            
            guard let imageCropper = ImageCropper(ciContext: self.ciContext!, img: sampleBuffer) else {
                debugPrint("failed to initialize image cropper")
                return
            }
            guard let deviceRange = deviceRange else {
                return
            }
            
            guard let cropped = imageCropper.cropAll(range: deviceRange) else {
                debugPrint("failed to crop all")
                return
            }
            
            self.postCroppedImages(image: cropped)
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
    
    var previousChoice3Png: Data?
    var previousEventName = ""
    var previousTime: Double = 0
    
    func postCroppedImages(image: CroppedImage) {
        let choice3Png = image.choice3.pngData()

        if previousChoice3Png != nil && choice3Png == previousChoice3Png {
            return
        }
        self.previousChoice3Png = choice3Png
        
        AF.upload(multipartFormData: {data in
            data.append(image.title.jpegData(compressionQuality: 0.5) ?? Data(), withName: "title", fileName: "title.jpg", mimeType: "image/jpeg")
            data.append(image.choice1.jpegData(compressionQuality: 0.5) ?? Data(), withName: "choice1", fileName: "choice1.jpg", mimeType: "image/jpeg")
            data.append(image.choice2.jpegData(compressionQuality: 0.5) ?? Data(), withName: "choice2", fileName: "choice2.jpg", mimeType: "image/jpeg")
            data.append(image.choice3.jpegData(compressionQuality: 0.5) ?? Data(), withName: "choice3", fileName: "choice3.jpg", mimeType: "image/jpeg")
        }, to: "YOUR_URL").responseJSON { response in
            guard let json = response.data else{
                return
            }
            
            do {
                let data = try JSONDecoder().decode(Result.self, from: json)
                
                if !data.ok {
                    return
                }

                DispatchQueue.main.async {
                    let now = Date().timeIntervalSince1970
                    
                    if now - self.previousTime < 10 && self.previousEventName == data.eventName {
                        return
                    }
                    debugPrint(now - self.previousTime)
                    debugPrint(self.previousEventName, data.eventName)
                    self.previousTime = now
                    self.previousEventName = data.eventName

                    
                    let notification = UNMutableNotificationContent()
                    notification.title = data.eventName
                    notification.categoryIdentifier = "event-notification"
                    notification.userInfo = ["result": json]

                    let request = UNNotificationRequest(identifier: "notification1", content: notification, trigger: nil)

                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
            } catch {
                debugPrint("error!")
            }
        }
    }
}
