//
//  ClipMaker.swift
//  JuiceClipMaker
//
//  Created by sergey on 10.10.2020.
//

import UIKit
import AVFoundation

enum Errors: Swift.Error {
  case assetError
  case audioError
  case exportSessionCreationError
  case exportError
}

class ClipMaker: VideoDecorator {

  func decorateVideoWithEffects(videoURL: URL,
                                textOverlay: TextOverlayConfig,
                                onComplete: @escaping (Result<URL, Error>) -> Void) {
    let asset = AVURLAsset(url: videoURL)
    let composition = AVMutableComposition()

    let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    guard let compositionTrack = compTrack,
          let assetTrack = asset.tracks(withMediaType: .video).first else {
      onComplete(.failure(Errors.assetError))
      return
    }

    do {
      let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
      try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)

      let audioComp = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
         let compositionAudioTrack = audioComp {

        try compositionAudioTrack.insertTimeRange(
          timeRange,
          of: audioAssetTrack,
          at: .zero
        )
      }
    } catch {
      onComplete(.failure(Errors.audioError))
      return
    }

    compositionTrack.preferredTransform = assetTrack.preferredTransform

    let videoInfo = self.orientation(from: assetTrack.preferredTransform)

    let videoSize: CGSize
    if videoInfo.isPortrait {
      videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
    } else {
      videoSize = assetTrack.naturalSize
    }

    let backgroundLayer = CALayer()
    backgroundLayer.frame = CGRect(origin: .zero, size: videoSize)
    let videoLayer = CALayer()
    videoLayer.frame = CGRect(origin: .zero, size: videoSize)
    let overlayLayer = CALayer()
    overlayLayer.frame = CGRect(origin: .zero, size: videoSize)

    let color = UIColor(red: 85.0/255, green: 153.0/255, blue: 236.0/255, alpha: 1)
    backgroundLayer.backgroundColor = color.cgColor
    videoLayer.frame = CGRect(
      x: 20,
      y: 20,
      width: videoSize.width - 40,
      height: videoSize.height - 40)

    backgroundLayer.contents = UIImage.from(color: color).cgImage
    backgroundLayer.contentsGravity = .resizeAspectFill

    self.add(textOverlay: textOverlay, to: overlayLayer, videoSize: videoSize)

    let outputLayer = CALayer()
    outputLayer.frame = CGRect(origin: .zero, size: videoSize)
    outputLayer.addSublayer(backgroundLayer)
    outputLayer.addSublayer(videoLayer)
    outputLayer.addSublayer(overlayLayer)

    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = videoSize
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
      postProcessingAsVideoLayer: videoLayer,
      in: outputLayer
    )

    let instruction = AVMutableVideoCompositionInstruction()

    instruction.timeRange = CMTimeRange(
      start: .zero,
      duration: composition.duration
    )

    videoComposition.instructions = [instruction]

    let layerInstruction = compositionLayerInstruction(
      for: compositionTrack,
      assetTrack: assetTrack
    )
    instruction.layerInstructions = [layerInstruction]

    guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
      onComplete(.failure(Errors.exportSessionCreationError))
      return
    }

    let tempDirectory = NSTemporaryDirectory()
    let tempVideoName = UUID().uuidString
    let exportURL = URL(fileURLWithPath: tempDirectory.appending(tempVideoName).appending(".mp4"))
    export.shouldOptimizeForNetworkUse = true
    export.videoComposition = videoComposition

    export.outputFileType = .mp4
    export.outputURL = exportURL

    export.exportAsynchronously {
      DispatchQueue.main.async {
        switch export.status {
        case .completed:
          onComplete(.success(exportURL))
        default:
          print(export.error ?? "unknown error")
          onComplete(.failure(export.error ?? Errors.exportError))
          break
        }
      }
    }
  }
  
  func decorateVideoWithEffects(videoURL: URL, addingText text: String, onComplete: @escaping (Result<URL, Error>) -> Void) {
    let asset = AVURLAsset(url: videoURL)
    let composition = AVMutableComposition()

    let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    guard let compositionTrack = compTrack,
          let assetTrack = asset.tracks(withMediaType: .video).first else {
      onComplete(.failure(Errors.assetError))
      return
    }

    do {
      let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
      try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)

      let audioComp = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
         let compositionAudioTrack = audioComp {

        try compositionAudioTrack.insertTimeRange(
          timeRange,
          of: audioAssetTrack,
          at: .zero
        )
      }
    } catch {
      onComplete(.failure(Errors.audioError))
      return
    }

    compositionTrack.preferredTransform = assetTrack.preferredTransform

    let videoInfo = self.orientation(from: assetTrack.preferredTransform)

    let videoSize: CGSize
    if videoInfo.isPortrait {
      videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
    } else {
      videoSize = assetTrack.naturalSize
    }

    let backgroundLayer = CALayer()
    backgroundLayer.frame = CGRect(origin: .zero, size: videoSize)
    let videoLayer = CALayer()
    videoLayer.frame = CGRect(origin: .zero, size: videoSize)
    let overlayLayer = CALayer()
    overlayLayer.frame = CGRect(origin: .zero, size: videoSize)

    let color = UIColor(red: 85.0/255, green: 153.0/255, blue: 236.0/255, alpha: 1)
    backgroundLayer.backgroundColor = color.cgColor
    videoLayer.frame = CGRect(
      x: 20,
      y: 20,
      width: videoSize.width - 40,
      height: videoSize.height - 40)

    backgroundLayer.contents = UIImage.from(color: color).cgImage
    backgroundLayer.contentsGravity = .resizeAspectFill

    self.add(
      text: text,
      backgroundColor: color,
      to: overlayLayer,
      videoSize: videoSize
    )

    let outputLayer = CALayer()
    outputLayer.frame = CGRect(origin: .zero, size: videoSize)
    outputLayer.addSublayer(backgroundLayer)
    outputLayer.addSublayer(videoLayer)
    outputLayer.addSublayer(overlayLayer)

    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = videoSize
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
      postProcessingAsVideoLayer: videoLayer,
      in: outputLayer
    )

    let instruction = AVMutableVideoCompositionInstruction()

    instruction.timeRange = CMTimeRange(
      start: .zero,
      duration: composition.duration
    )

    videoComposition.instructions = [instruction]

    let layerInstruction = compositionLayerInstruction(
      for: compositionTrack,
      assetTrack: assetTrack
    )
    instruction.layerInstructions = [layerInstruction]

    guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
      onComplete(.failure(Errors.exportSessionCreationError))
      return
    }

    let tempDirectory = NSTemporaryDirectory()
    let tempVideoName = UUID().uuidString
    let exportURL = URL(fileURLWithPath: tempDirectory.appending(tempVideoName).appending(".mp4"))
    export.shouldOptimizeForNetworkUse = true
    export.videoComposition = videoComposition

    export.outputFileType = .mp4
    export.outputURL = exportURL

    export.exportAsynchronously {
      DispatchQueue.main.async {
        switch export.status {
        case .completed:
          onComplete(.success(exportURL))
        default:
          print(export.error ?? "unknown error")
          onComplete(.failure(export.error ?? Errors.exportError))
          break
        }
      }
    }
  }

  private func add(textOverlay: TextOverlayConfig, to layer: CALayer, videoSize: CGSize) {
    let titleSize = textOverlay.title.boundingRect(
      with: videoSize,
      options: .usesFontLeading,
      context: nil
    )

    var bodySizes: [CGSize] = []
    var remainingHeight = videoSize.height - titleSize.height
    for line in textOverlay.bodyLines {
      let rect = line.boundingRect(
        with: CGSize(width: videoSize.width, height: remainingHeight),
        options: .usesFontLeading,
        context: nil
      )
      bodySizes.append(rect.size)
      remainingHeight -= rect.height
      if remainingHeight <= 0 {
        break
      }
    }

    let maxWidth = bodySizes.max(by: { $0.width < $1.width })?.width ?? titleSize.width

    let overallTextSize = CGSize(
      width: max(titleSize.width, maxWidth),
      height: titleSize.height + bodySizes.compactMap { $0.height }.reduce (0, +)
    )

    let titleLayer = CATextLayer()
    titleLayer.string = textOverlay.title
    titleLayer.backgroundColor = UIColor.clear.cgColor

    titleLayer.frame = CGRect(
      x: -titleSize.width,
      y: overallTextSize.height,
      width: titleSize.width + 24,
      height: titleSize.height
    )
    titleLayer.displayIfNeeded()


    let frameAnimation = CABasicAnimation(keyPath: "position.x")
    frameAnimation.fromValue = -titleSize.width
    frameAnimation.toValue = titleSize.width/2 + 40
    frameAnimation.duration = 0.8
    frameAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    frameAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
    frameAnimation.autoreverses = false
    frameAnimation.isRemovedOnCompletion = true
    titleLayer.position.x = titleSize.width/2 + 40

    titleLayer.add(frameAnimation, forKey: nil)

    layer.addSublayer(titleLayer)
    titleLayer.setNeedsDisplay()

    var yPosition = overallTextSize.height
    zip(bodySizes, textOverlay.bodyLines).enumerated().forEach { (offset, element) in

      let (size, text) = element
      yPosition -= size.height
      let textLayer = CATextLayer()
      textLayer.string = text
      textLayer.backgroundColor = UIColor.clear.cgColor

      textLayer.frame = CGRect(
        x: -size.width,
        y: yPosition,
        width: size.width + 24,
        height: size.height
      )
      textLayer.displayIfNeeded()

      let frameAnimation = CABasicAnimation(keyPath: "position.x")
      frameAnimation.fromValue = -size.width
      frameAnimation.toValue = size.width/2 + 40
      frameAnimation.duration = 0.8
      frameAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      frameAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
      frameAnimation.autoreverses = false
      frameAnimation.isRemovedOnCompletion = true
      textLayer.position.x = size.width/2 + 40

      textLayer.add(frameAnimation, forKey: nil)

      layer.addSublayer(textLayer)
      textLayer.setNeedsDisplay()
    }
  }

  private func add(text: String, backgroundColor: UIColor, to layer: CALayer, videoSize: CGSize) {
    let attributedText = NSAttributedString(
      string: text,
      attributes: [
        .font: UIFont.systemFont(ofSize: 35),
        .foregroundColor: UIColor.white,
        .strokeColor: UIColor.white,
        .strokeWidth: -3,
      ]
    )

    let textRect = attributedText.boundingRect(
      with: videoSize,
      options: .usesFontLeading,
      context: nil
    )

    let textLayer = CATextLayer()
    textLayer.string = attributedText
    textLayer.backgroundColor = backgroundColor.cgColor
    textLayer.alignmentMode = .center
    textLayer.cornerRadius = 4

    textLayer.frame = CGRect(
      x: -textRect.width,
      y: textRect.height,
      width: textRect.width + 24,
      height: textRect.height)
    textLayer.displayIfNeeded()


    let frameAnimation = CABasicAnimation(keyPath: "position.x")
    frameAnimation.fromValue = -textRect.width
    frameAnimation.toValue = textRect.width/2 + 40
    frameAnimation.duration = 0.8
    frameAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    frameAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
    frameAnimation.autoreverses = false
    frameAnimation.isRemovedOnCompletion = true
    textLayer.position.x = textRect.width/2 + 40

    textLayer.add(frameAnimation, forKey: nil)

    layer.addSublayer(textLayer)
    textLayer.setNeedsDisplay()
  }
}

extension UIImage {
  static func from(color: UIColor, rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> UIImage {
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    context!.setFillColor(color.cgColor)
    context!.fill(rect)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
  }
}
