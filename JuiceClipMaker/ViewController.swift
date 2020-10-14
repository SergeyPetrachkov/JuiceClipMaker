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
import Foundation

final class ViewController: UIViewController {
  // MARK: - Essentials
  private let editor = ClipMaker()

  let composerQueue = DispatchQueue(label: "video.composing.queue", attributes: .concurrent)
  let videoEditorQueue = DispatchQueue(label: "video.editor.queue", attributes: .concurrent)

  // MARK: - UI
  var player: AVPlayer?
  var layer: AVPlayerLayer?
  lazy var videoView: UIView = UIView(
    frame: .init(origin: .zero,
                 size: .init(width: self.view.bounds.width,
                             height: self.view.bounds.width * 0.667)
    )
  )


  func processVideo(at url: URL, text: String, on queue: DispatchQueue) -> URL {
    var resultUrl: URL?
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    queue.async {
      self.editor.decorateVideoWithEffects(videoURL: url, addingText: text) { result in
        resultUrl = try? result.get()
        dispatchGroup.leave()
      }
    }
    dispatchGroup.wait()
    return resultUrl ?? url
  }

  func processVideo(at url: URL, textOverlay: TextOverlayConfig, on queue: DispatchQueue) -> URL {
    var resultUrl: URL?
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    queue.async {
      self.editor.decorateVideoWithEffects(videoURL: url, textOverlay: textOverlay) { result in
        resultUrl = try? result.get()
        dispatchGroup.leave()
      }
    }
    dispatchGroup.wait()
    return resultUrl ?? url
  }

  // MARK: - Life cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    self.videoView.center = self.view.center
    self.view.addSubview(videoView)
    let inputVideos: [URL] = [
      "https://juiceapp.cc/storage/videos/2936/KqpwfYBMN72J8CYVDhM1Q4UU4RtNSf.mp4",
      "https://juiceapp.cc/storage/videos/2936/praQXLAzWG4xCKMn7bi75glvrSbuYT.mp4",
      "https://juiceapp.cc/storage/videos/2936/BS1lFFZUa4j6nfES6WsZ2mgJr9LtgL.mp4",
      "https://juiceapp.cc/storage/videos/2936/13rb3QPu5tyhqRNyd5PuEMOa6FD8LW.mp4",
      "https://juiceapp.cc/storage/videos/2936/sxS9mSHqPQFj9KFlNcLxwLZj5jmQJq.mp4"
    ].map { URL(string: $0) }.compactMap { $0 }

    self.composerQueue.async {
      let titleAttributes: TextOverlayConfig.TextAttributes = [
        .font: UIFont.systemFont(ofSize: 35),
                             .foregroundColor: UIColor.white,
                             .strokeColor: UIColor.white,
                             .strokeWidth: -3,
      ]

      let bodyAttributes: TextOverlayConfig.TextAttributes = [
        .font: UIFont.italicSystemFont(ofSize: 20),
        .foregroundColor: UIColor.darkGray,
        .strokeColor: UIColor.darkGray,
        .strokeWidth: -3,
      ]
      let videos = inputVideos
        .enumerated()
        .map { self.processVideo(
          at: $0.element,
          textOverlay: TextOverlayConfig(
            title: .init(string: "Title \($0.offset)", attributes: titleAttributes),
            bodyLines: [.init(string: "Reps 10", attributes: bodyAttributes),
                        .init(string: "Sets 2", attributes: bodyAttributes)]
          ),
          on: self.videoEditorQueue) }

      self.editor.mergeVideos(urls: videos) { result in
        switch result {
        case .success(let exportedURL):
          DispatchQueue.main.async {
            self.showVideo(url: exportedURL)
          }
        case .failure(let error):
          print(error)
          DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error!", message: error.localizedDescription, preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
          }
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
