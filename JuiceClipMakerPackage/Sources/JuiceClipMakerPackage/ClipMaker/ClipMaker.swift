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
    videoLayer.frame = CGRect(origin: .zero, size: videoSize)
    // TODO: - blue border
//      CGRect(
//      x: 20,
//      y: 20,
//      width: videoSize.width - 40,
//      height: videoSize.height - 40
//    )

    backgroundLayer.contents = UIImage.from(color: color).cgImage
    backgroundLayer.contentsGravity = .resizeAspectFill

    self.add(textOverlay: textOverlay, to: overlayLayer, videoSize: videoSize)

    let outputLayer = CALayer()
    outputLayer.frame = CGRect(origin: .zero, size: videoSize)
//    outputLayer.addSublayer(backgroundLayer)
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

  // MARK: - Add text overlay

  private func add(textOverlay: TextOverlayConfig, to layer: CALayer, videoSize: CGSize) {
    var superTitleTiming: CFTimeInterval = AVCoreAnimationBeginTimeAtZero
    let color = UIColor(red: 85.0/255, green: 169.0/255, blue: 244.0/255, alpha: 1)

    // MARK: - Super title
    if let superTitle = textOverlay.superTitle {
      superTitleTiming = 2

      let width: CGFloat = videoSize.width - 60
      let superTitleSize = superTitle.boundingRect(
        with: CGSize(width: width, height: videoSize.height),
        options: .usesLineFragmentOrigin,
        context: nil
      )

      let yPosition = (videoSize.height - superTitleSize.height)/2

      let titleBackgroundLayer = CALayer()
      titleBackgroundLayer.backgroundColor = color.cgColor
      titleBackgroundLayer.cornerRadius = 0
      titleBackgroundLayer.frame = CGRect(origin: CGPoint(x: -videoSize.width, y: yPosition), size: CGSize(width: videoSize.width, height: superTitleSize.height))

      let superTitleBackgroundLayerAnimation = CAKeyframeAnimation(keyPath: "position.x")
      superTitleBackgroundLayerAnimation.values = [-videoSize.width, videoSize.width/2, videoSize.width/2, 2*videoSize.width]
      superTitleBackgroundLayerAnimation.keyTimes = [0, 0.2, 0.9, 1]
      superTitleBackgroundLayerAnimation.duration = superTitleTiming
      superTitleBackgroundLayerAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      superTitleBackgroundLayerAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
      superTitleBackgroundLayerAnimation.autoreverses = false
      superTitleBackgroundLayerAnimation.isRemovedOnCompletion = false
      superTitleBackgroundLayerAnimation.fillMode = .forwards

      titleBackgroundLayer.add(superTitleBackgroundLayerAnimation, forKey: "super.title.background.animation")

      layer.addSublayer(titleBackgroundLayer)
      titleBackgroundLayer.setNeedsDisplay()

      let superTitleLayer = CATextLayer()
      superTitleLayer.string = superTitle
      superTitleLayer.backgroundColor = UIColor.clear.cgColor
      superTitleLayer.cornerRadius = 0
      superTitleLayer.alignmentMode = .center
      superTitleLayer.opacity = 0
      superTitleLayer.isWrapped = true
      superTitleLayer.frame = CGRect(
        origin: CGPoint(x: 20, y: yPosition),
        size: CGSize(width: videoSize.width - 40, height: superTitleSize.height)
      )

      let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
      opacityAnimation.values = [0, 0, 1, 1, 0, 0]
      opacityAnimation.keyTimes = [0, 0.2, 0.4, 0.7, 1]
      opacityAnimation.duration = superTitleTiming
      opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      opacityAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
      opacityAnimation.autoreverses = false
      opacityAnimation.isRemovedOnCompletion = false
      opacityAnimation.fillMode = .forwards

      superTitleLayer.add(opacityAnimation, forKey: "super.title.opacity.animation")

      layer.addSublayer(superTitleLayer)
      superTitleLayer.setNeedsDisplay()
    }

    // MARK: - Calculate text sizes
    let width: CGFloat = videoSize.width - 60
    let titleSize = textOverlay.title.boundingRect(
      with: CGSize(width: width, height: videoSize.height),
      options: .usesLineFragmentOrigin,
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

    // MARK: - Title section setup
    let titleBackgroundLayer = CALayer()
    let xOrigin = -titleSize.width - 45
    titleBackgroundLayer.backgroundColor = color.cgColor
    titleBackgroundLayer.cornerRadius = 4
    let backgroundSize = CGSize(width: titleSize.width + 24, height: titleSize.height)
    let initialBackgroundRect = CGRect(
      origin: .init(x: xOrigin, y: overallTextSize.height),
      size: backgroundSize
    )
    titleBackgroundLayer.frame = initialBackgroundRect
    // MARK: - title background slide from the left
    let titleBackgroundSlideAnimationDuration: CFTimeInterval = 0.8
    let titleBackgroundSlideAnimation = CABasicAnimation(keyPath: "position.x")
    titleBackgroundSlideAnimation.fromValue = xOrigin
    titleBackgroundSlideAnimation.toValue = titleSize.width/2 + 40
    titleBackgroundSlideAnimation.duration = titleBackgroundSlideAnimationDuration
    titleBackgroundSlideAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    titleBackgroundSlideAnimation.beginTime = AVCoreAnimationBeginTimeAtZero + superTitleTiming
    titleBackgroundSlideAnimation.autoreverses = false
    titleBackgroundSlideAnimation.isRemovedOnCompletion = false
    titleBackgroundSlideAnimation.fillMode = .forwards

    titleBackgroundLayer.add(titleBackgroundSlideAnimation, forKey: nil)

    // MARK: - title background resize animation group
    let titleBackgroundFrameAnimation = CABasicAnimation(keyPath: "bounds")
    titleBackgroundFrameAnimation.fromValue = CGRect(origin: titleBackgroundLayer.anchorPoint, size: titleSize.size)
    titleBackgroundFrameAnimation.toValue = CGRect(origin: titleBackgroundLayer.anchorPoint, size: CGSize(width: 10, height: titleSize.height))

    let titleBackgroundRestorePositionAnimation = CABasicAnimation(keyPath: "position.x")
    titleBackgroundRestorePositionAnimation.fromValue = titleSize.width/2 + 40
    titleBackgroundRestorePositionAnimation.toValue = 36

    let group = CAAnimationGroup()
    group.fillMode = .forwards
    group.duration = 0.45
    group.beginTime = superTitleTiming + titleBackgroundSlideAnimationDuration - 0.1
    group.timingFunction = CAMediaTimingFunction(name: .linear)
    group.isRemovedOnCompletion = false
    group.animations = [titleBackgroundRestorePositionAnimation, titleBackgroundFrameAnimation]

    titleBackgroundLayer.add(titleBackgroundSlideAnimation, forKey: nil)
    titleBackgroundLayer.add(group, forKey: "frame")

    layer.addSublayer(titleBackgroundLayer)
    titleBackgroundLayer.setNeedsDisplay()
    // MARK: - title layer
    let titleLayer = CATextLayer()
    titleLayer.string = textOverlay.title
    titleLayer.backgroundColor = UIColor.clear.cgColor
    titleLayer.alignmentMode = .left
    titleLayer.isWrapped = true

    titleLayer.frame = CGRect(
      x: xOrigin,
      y: overallTextSize.height,
      width: titleSize.width + 24,
      height: titleSize.height
    )
    titleLayer.displayIfNeeded()
    // MARK: - title layer slide from the left
    let frameAnimation = CABasicAnimation(keyPath: "position.x")
    frameAnimation.fromValue = xOrigin
    frameAnimation.toValue = titleSize.width/2 + 46
    frameAnimation.duration = 0.8
    frameAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    frameAnimation.beginTime = superTitleTiming
    frameAnimation.autoreverses = false
    frameAnimation.isRemovedOnCompletion = false
    frameAnimation.fillMode = .forwards

    titleLayer.add(frameAnimation, forKey: nil)

    layer.addSublayer(titleLayer)
    titleLayer.setNeedsDisplay()

    // MARK: - Body lines
    var yPosition = overallTextSize.height
    zip(bodySizes, textOverlay.bodyLines).enumerated().forEach { (offset, element) in

      let (size, text) = element
      yPosition -= size.height + 2
      let textLayer = CATextLayer()
      textLayer.string = text
      textLayer.backgroundColor = UIColor.white.cgColor
      textLayer.cornerRadius = 4
      textLayer.alignmentMode = .center
      textLayer.opacity = 0
      textLayer.frame = CGRect(
        x: 30,
        y: yPosition,
        width: maxWidth + 24,
        height: size.height
      )

      let opacityAnimation = CABasicAnimation(keyPath: "opacity")
      let animationDuration = 0.5
      opacityAnimation.fromValue = 0
      opacityAnimation.toValue = 1
      opacityAnimation.duration = animationDuration
      opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      opacityAnimation.beginTime = superTitleTiming + titleBackgroundSlideAnimationDuration + Double(offset)*animationDuration
      opacityAnimation.autoreverses = false
      opacityAnimation.isRemovedOnCompletion = false
      opacityAnimation.fillMode = .forwards

      textLayer.add(opacityAnimation, forKey: nil)

      layer.addSublayer(textLayer)
      textLayer.setNeedsDisplay()
    }
  }

  // MARK: - Add simple text
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
