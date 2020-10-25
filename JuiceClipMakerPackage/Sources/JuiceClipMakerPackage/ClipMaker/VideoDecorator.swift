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

public protocol VideoDecorator: VideoCompositionManager {
  func decorateVideoWithEffects(videoURL: URL, addingText text: String, onComplete: @escaping (Result<URL, Error>) -> Void)
  func decorateVideoWithEffects(videoURL: URL,
                                textOverlay: TextOverlayConfig,
                                onComplete: @escaping (Result<URL, Error>) -> Void)
}
