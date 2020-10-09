//
//  ViewController.swift
//  JuiceClipMaker
//
//  Created by sergey on 09.10.2020.
//

import MobileCoreServices
import UIKit
import AVKit
import Photos
import SPMAssetExporter

class ViewController: UIViewController {

  let editor = VideoEditor()

  var player: AVPlayer?
  var layer: AVPlayerLayer?
  lazy var videoView: UIView = UIView(frame: .init(origin: .zero, size: .init(width: self.view.bounds.width, height: self.view.bounds.width * 0.667)))

  override func viewDidLoad() {
    super.viewDidLoad()
    let filePath = Bundle.main.path(forResource: "0EjMgqLc1qNtiEA5Wh7qNqXT46RBGW", ofType: "mp4")!
    let url = URL(string: "file://\(filePath)")!
    self.videoView.center = self.view.center
    self.view.addSubview(videoView)
//    let player = AVPlayer(url: url)
//    let playerLayer = AVPlayerLayer(player: player)
//    self.player = player
//    self.layer = playerLayer
//    playerLayer.frame = videoView.bounds
//    videoView.layer.addSublayer(playerLayer)
//    player.play()

  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
//    /Users/sergey/Downloads/New Folder With Items/9010D842-CB8B-4C21-B2E3-2254D6209DEA.MP4
//    let filePath = Bundle.main.path(forResource: "0EjMgqLc1qNtiEA5Wh7qNqXT46RBGW", ofType: "mp4")!
    let filePath = Bundle.main.path(forResource: "9010D842-CB8B-4C21-B2E3-2254D6209DEA", ofType: "MP4")!
//    "/Users/sergey/Downloads/New Folder With Items/9010D842-CB8B-4C21-B2E3-2254D6209DEA.MP4"
//    let ch = URL(string: "/Users/sergey/Downloads/New Folder With Items/9010D842-CB8B-4C21-B2E3-2254D6209DEA.MP4")
    let url = URL(fileURLWithPath: filePath)
    self.generate(url: url, name: "Hello there! Push-ups")
//    self.pickVideo(from: .photoLibrary)
  }
  func generate(url: URL, name: String) {
    self.editor.makeBirthdayCard(fromVideoAt: url, forName: name) { [weak self] exportedURL in
      guard let self = self else {
        return
      }
      guard let exportedURL = exportedURL else {
        return
      }
      self.layer?.removeFromSuperlayer()
      self.player = nil
      let player = AVPlayer(url: exportedURL)
      let playerLayer = AVPlayerLayer(player: player)
      self.player = player
      self.layer = playerLayer
      playerLayer.frame = self.videoView.bounds
      self.videoView.layer.addSublayer(playerLayer)
      player.play()
    }
  }
  private func pickVideo(from sourceType: UIImagePickerController.SourceType) {
    let pickerController = UIImagePickerController()
    pickerController.sourceType = sourceType
    pickerController.mediaTypes = [kUTTypeMovie as String]
    pickerController.videoQuality = .typeIFrame1280x720
    if sourceType == .camera {
      pickerController.cameraDevice = .front
    }
    pickerController.delegate = self
    present(pickerController, animated: true)
  }

  private func showVideo(at url: URL) {
    let player = AVPlayer(url: url)
    let playerViewController = AVPlayerViewController()
    playerViewController.player = player
    present(playerViewController, animated: true) {
      player.play()
    }
  }

  private var pickedURL: URL?
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    guard
      let url = info[.mediaURL] as? URL
    else {
      print("Cannot get video URL")
      return
    }

    picker.dismiss(animated: true) {
      self.generate(url: url, name: "Testing label")
//      self.editor.makeBirthdayCard(fromVideoAt: url, forName: name) { exportedURL in
//        self.showCompleted()
//        guard let exportedURL = exportedURL else {
//          return
//        }
//        self.pickedURL = exportedURL
//
//      }
    }
  }
}


import AVFoundation

class VideoEditor {
  func makeBirthdayCard(fromVideoAt videoURL: URL, forName name: String, onComplete: @escaping (URL?) -> Void) {
    print(videoURL)
    let asset = AVURLAsset(url: videoURL)
    let composition = AVMutableComposition()

    let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    guard let compositionTrack = compTrack,
      let assetTrack = asset.tracks(withMediaType: .video).first else {
      print("Something is wrong with the asset.")
      onComplete(nil)
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
      print(error)
      onComplete(nil)
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

//    addConfetti(to: overlayLayer)
//    addImage(to: overlayLayer, videoSize: videoSize)

    add(
      text: "\(name)",
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
      print("Cannot create export session.")
      onComplete(nil)
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
          onComplete(exportURL)
        default:
          print("Something went wrong during export.")
          print(export.error ?? "unknown error")
          onComplete(nil)
          break
        }
      }
    }
  }

  private func addImage(to layer: CALayer, videoSize: CGSize) {
    let image = UIImage(named: "overlay")!
    let imageLayer = CALayer()

    let aspect: CGFloat = image.size.width / image.size.height
    let width = videoSize.width
    let height = width / aspect
    imageLayer.frame = CGRect(
      x: 0,
      y: -height * 0.15,
      width: width,
      height: height)

    imageLayer.contents = image.cgImage
    layer.addSublayer(imageLayer)
  }

  private func add(text: String, to layer: CALayer, videoSize: CGSize) {
    let attributedText = NSAttributedString(
      string: text,
      attributes: [
        .font: UIFont.systemFont(ofSize: 40),
        .foregroundColor: UIColor.white,
        .strokeColor: UIColor.white,
        .strokeWidth: -3])

    let textLayer = CATextLayer()
    textLayer.string = attributedText
    textLayer.shouldRasterize = true
    textLayer.rasterizationScale = UIScreen.main.scale
    textLayer.backgroundColor = UIColor.clear.cgColor
    textLayer.alignmentMode = .center

    textLayer.frame = CGRect(
      x: 0,
      y: 20,//videoSize.height * 0.66,
      width: videoSize.width,
      height: 150)
    textLayer.displayIfNeeded()

    let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
    scaleAnimation.fromValue = 0.8
    scaleAnimation.toValue = 1.2
    scaleAnimation.duration = 0.5
    scaleAnimation.repeatCount = .greatestFiniteMagnitude
    scaleAnimation.autoreverses = true
    scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    scaleAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
    scaleAnimation.isRemovedOnCompletion = false
    textLayer.add(scaleAnimation, forKey: "scale")

    layer.addSublayer(textLayer)
  }

  private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
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

  private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
    let transform = assetTrack.preferredTransform

    instruction.setTransform(transform, at: .zero)

    return instruction
  }

  private func addConfetti(to layer: CALayer) {
    let images: [UIImage] = (0...5).map { UIImage(named: "confetti\($0)")! }
    let colors: [UIColor] = [.systemGreen, .systemRed, .systemBlue, .systemPink, .systemOrange, .systemPurple, .systemYellow]
    let cells: [CAEmitterCell] = (0...16).map { _ in
      let cell = CAEmitterCell()
      cell.contents = images.randomElement()?.cgImage
      cell.birthRate = 3
      cell.lifetime = 12
      cell.lifetimeRange = 0
      cell.velocity = CGFloat.random(in: 100...200)
      cell.velocityRange = 0
      cell.emissionLongitude = 0
      cell.emissionRange = 0.8
      cell.spin = 4
      cell.color = colors.randomElement()?.cgColor
      cell.scale = CGFloat.random(in: 0.2...0.8)
      return cell
    }

    let emitter = CAEmitterLayer()
    emitter.emitterPosition = CGPoint(x: layer.frame.size.width / 2, y: layer.frame.size.height + 5)
    emitter.emitterShape = .line
    emitter.emitterSize = CGSize(width: layer.frame.size.width, height: 2)
    emitter.emitterCells = cells

    layer.addSublayer(emitter)
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
