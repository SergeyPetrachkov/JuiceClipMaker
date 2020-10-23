//
//  VideoDecorator.swift
//  JuiceClipMaker
//
//  Created by sergey on 10.10.2020.
//

import UIKit
import AVFoundation

public protocol VideoCompositionManager: AnyObject {}

public extension VideoCompositionManager {
  func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
    var assetOrientation = UIImage.Orientation.up
    var isPortrait = false
    if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
      assetOrientation = .right
      isPortrait = true
    } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
      assetOrientation = .left
      isPortrait = true
    } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
      assetOrientation = .up
    } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
      assetOrientation = .down
    }

    return (assetOrientation, isPortrait)
  }

  func compositionLayerInstruction(
    for track: AVCompositionTrack,
    assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {

    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
    let transform = assetTrack.preferredTransform

    instruction.setTransform(transform, at: .zero)

    return instruction
  }
}

public extension VideoCompositionManager {
  func mergeVideos(urls: [URL], completion: @escaping (Result<URL, Error>) -> Void) {
    let composition = AVMutableComposition()
    var currentTime = CMTime.zero
    var renderSize = CGSize.zero
    // Create empty Layer Instructions, that we will be passing to Video Composition and finally to Exporter.
    var instructions = [AVMutableVideoCompositionInstruction]()

    urls.enumerated().forEach { index, url in
      let asset = AVAsset(url: url)
      let assetTrack = asset.tracks(withMediaType: .video).first!
      let maxRenderSize = assetTrack.naturalSize
      // Create instruction for a video and append it to array.
      let instruction = AVMutableComposition.instruction(assetTrack, asset: asset, time: currentTime, duration: assetTrack.timeRange.duration, maxRenderSize: maxRenderSize)
      instructions.append(instruction.videoCompositionInstruction)

      // Set render size (orientation) according first video.
      if index == 0 {
        renderSize = instruction.isPortrait ? CGSize(width: maxRenderSize.height, height: maxRenderSize.width) : CGSize(width: maxRenderSize.width, height: maxRenderSize.height)
      }

      do {
        let timeRange = CMTimeRangeMake(start: .zero, duration: assetTrack.timeRange.duration)
        // Insert video to Mutable Composition at right time.
        try composition.insertTimeRange(timeRange, of: asset, at: currentTime)
        currentTime = CMTimeAdd(currentTime, assetTrack.timeRange.duration)
      } catch let error {
        completion(.failure(error))
      }
    }

    // Create Video Composition and pass Layer Instructions to it.
    let videoComposition = AVMutableVideoComposition()
    videoComposition.instructions = instructions
    // Do not forget to set frame duration and render size. It will crash if you dont.
    videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    videoComposition.renderSize = renderSize

    guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
      completion(.failure(Errors.exportSessionCreationError))
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
          completion(.success(exportURL))
        default:
          print(export.error ?? "unknown error")
          completion(.failure(export.error ?? Errors.exportError))
          break
        }
      }
    }
  }
}

public protocol VideoDecorator: VideoCompositionManager {
  func decorateVideoWithEffects(videoURL: URL, addingText text: String, onComplete: @escaping (Result<URL, Error>) -> Void)
  func decorateVideoWithEffects(videoURL: URL,
                                textOverlay: TextOverlayConfig,
                                onComplete: @escaping (Result<URL, Error>) -> Void)
}
