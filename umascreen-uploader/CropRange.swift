//
//  CropRangeStore.swift
//  umascreen-uploader
//
//  Created by Tsuzu on 2021/05/16.
//

import Foundation
import CoreImage
import UIKit

struct CropRange {
    var size: CGPoint
    var title, choice1, choice2, choice3: CGRect
}

class CropRangeStore {
    static func getRange(modelName: String)-> CropRange? {
        switch modelName {
        case "iPhone 12 mini":
            return CropRange(
                size: CGPoint(x: 1125, y: 2436),
                title: CGRect(x: 170, y: 533, width: 550, height: 48),
                choice1: CGRect(x: 125, y: 1164, width: 920, height: 48),
                choice2: CGRect(x: 125, y: 1340, width: 920, height: 48),
                choice3: CGRect(x: 125, y: 1516, width: 920, height: 48)
            )
        case "iPad Pro (12.9-inch) (3rd generation)":
            return CropRange(
                size: CGPoint(x: 2048, y: 2732),
                title: CGRect(x: 240, y: 524, width: 860, height: 60),
                choice1: CGRect(x: 427, y: 1240, width: 1250, height: 85),
                choice2: CGRect(x: 427, y: 1480, width: 1250, height: 85),
                choice3: CGRect(x: 427, y: 1720, width: 1250, height: 85)
            )
        default:
            return nil
        }
    }
}
