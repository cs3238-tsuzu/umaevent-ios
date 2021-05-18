//
//  ImageCropper.swift
//  umascreen-uploader
//
//  Created by Tsuzu on 2021/05/16.
//

import ReplayKit
import CoreMedia
import CoreImage

struct CroppedImage {
    var title, choice1, choice2, choice3: UIImage
}

class ImageCropper {
    let cgImage: CGImage
    
    init?(ciContext: CIContext, img: CMSampleBuffer) {
        guard let pixelBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(img) else {
            return nil
        }
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        if UIDevice.modelName.hasPrefix("iPad") {
            ciImage = ciImage.oriented(.right   )
        }
        
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        self.cgImage = cgImage
    }

    func crop(rect: CGRect)-> UIImage? {
        if rect.maxX > CGFloat(cgImage.width) || rect.maxY > CGFloat(cgImage.height) {
            return nil
        }
        debugPrint(cgImage.width, cgImage.height)
        
        guard let cgImage = cgImage.cropping(to: rect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    func cropAll(range: CropRange)-> CroppedImage? {
        guard let title = self.crop(rect: getAbsoluteRatio(target: range.title, size: range.size)) else {
            return nil
        }
        guard let choice1 = self.crop(rect: getAbsoluteRatio(target: range.choice1, size: range.size)) else {
            return nil
        }
        guard let choice2 = self.crop(rect: getAbsoluteRatio(target: range.choice2, size: range.size)) else {
            return nil
        }
        guard let choice3 = self.crop(rect: getAbsoluteRatio(target: range.choice3, size: range.size)) else {
            return nil
        }
        
        return CroppedImage(title: title, choice1: choice1, choice2: choice2, choice3: choice3)
    }
    
    func getAbsoluteRatio(target: CGRect, size: CGPoint)-> CGRect {
        let imageSize = CGPoint(x: cgImage.width, y: cgImage.height)
        
        return CGRect (
            x: target.minX / size.x * imageSize.x,
            y: target.minY / size.y * imageSize.y,
            width: target.width / size.x * imageSize.x,
            height: target.height / size.y * imageSize.y
        )
    }
}
