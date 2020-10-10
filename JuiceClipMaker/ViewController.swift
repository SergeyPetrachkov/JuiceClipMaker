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

final class ViewController: UIViewController {
  // MARK: - Essentials
  private let lockQueue = DispatchQueue(label: "locking.queue", attributes: .concurrent)

  private var videoUrls: [URL] = []

  private let editor = ClipMaker()

  // MARK: - UI
  var player: AVPlayer?
  var layer: AVPlayerLayer?
  lazy var videoView: UIView = UIView(frame: .init(origin: .zero, size: .init(width: self.view.bounds.width, height: self.view.bounds.width * 0.667)))

  // MARK: - Life cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    self.videoView.center = self.view.center
    self.view.addSubview(videoView)
    let dispatchGroup = DispatchGroup()

    DispatchQueue.global().async {

      dispatchGroup.enter()
      let filePath = Bundle.main.path(forResource: "9010D842-CB8B-4C21-B2E3-2254D6209DEA", ofType: "MP4")!
      let url = URL(fileURLWithPath: filePath)
      self.editor.decorateVideoWithEffects(videoURL: url, addingText: "Pushups") { [weak self] result in
        guard let self = self else {
          return
        }
        _ = result.map { videoUrl in
          self.lockQueue.async(flags: .barrier) {
            self.videoUrls.append(videoUrl)
            dispatchGroup.leave()
          }
        }
      }

      dispatchGroup.enter()
      let filePath2 = Bundle.main.path(forResource: "0EjMgqLc1qNtiEA5Wh7qNqXT46RBGW", ofType: "mp4")!
      let url2 = URL(fileURLWithPath: filePath2)
      self.editor.decorateVideoWithEffects(videoURL: url2, addingText: "Check check") { [weak self] result in
        guard let self = self else {
          return
        }
        _ = result.map { videoUrl in
          self.lockQueue.async(flags: .barrier) {
            self.videoUrls.append(videoUrl)
            dispatchGroup.leave()
          }
        }
      }

      dispatchGroup.wait()

      self.editor.mergeVideos(urls: self.videoUrls) { result in
        switch result {
        case .success(let exportedURL):
          self.showVideo(url: exportedURL)
        case .failure(let error):
          print(error)
        }
      }
    }
  }

  private func showVideo(url: URL) {
    self.layer?.removeFromSuperlayer()
    self.player = nil
    let player = AVPlayer(url: url)
    let playerLayer = AVPlayerLayer(player: player)
    self.player = player
    self.layer = playerLayer
    playerLayer.frame = self.videoView.bounds
    self.videoView.layer.addSublayer(playerLayer)
    player.play()
  }

  private func generate(url: URL, name: String) {
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
}
