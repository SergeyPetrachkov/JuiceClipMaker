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

  let editor = ClipMaker()

  var player: AVPlayer?
  var layer: AVPlayerLayer?
  lazy var videoView: UIView = UIView(frame: .init(origin: .zero, size: .init(width: self.view.bounds.width, height: self.view.bounds.width * 0.667)))

  override func viewDidLoad() {
    super.viewDidLoad()
    let filePath = Bundle.main.path(forResource: "0EjMgqLc1qNtiEA5Wh7qNqXT46RBGW", ofType: "mp4")!
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
    self.generate(url: url, name: "Push-ups")
//    self.pickVideo(from: .photoLibrary)
  }
  func generate(url: URL, name: String) {
    self.editor.decorateVideoWithEffects(videoURL: url, addingText: name) { [weak self] result in

      guard let self = self else {
        return
      }
      switch result {
      case .success(let exportedURL):
        self.layer?.removeFromSuperlayer()
        self.player = nil
        let player = AVPlayer(url: exportedURL)
        let playerLayer = AVPlayerLayer(player: player)
        self.player = player
        self.layer = playerLayer
        playerLayer.frame = self.videoView.bounds
        self.videoView.layer.addSublayer(playerLayer)
        player.play()
      case .failure(let error):
        print(error)
      }
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
