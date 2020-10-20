//
//  ViewController.swift
//  JuiceClipMaker
//
//  Created by sergey on 09.10.2020.
//

import UIKit
import AVKit
import Foundation
import Photos

public final class ClipMakerController: UIViewController {

  // MARK: - Configurators
  private let actionButtonConfig: ClipMakerActionButtonConfig
  private let dataContext: ClipMakerContext

  // MARK: - Initializers
  public init(actionButtonConfig: ClipMakerActionButtonConfig, dataContext: ClipMakerContext) {
    self.actionButtonConfig = actionButtonConfig
    self.dataContext = dataContext
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    self.actionButtonConfig = .init()
    let superTitleAttributes: TextOverlayConfig.TextAttributes = [
      .font: UIFont.systemFont(ofSize: 40),
      .foregroundColor: UIColor.white,
      .strokeColor: UIColor.white,
      .strokeWidth: -3,
    ]

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

    let texts: [TextOverlayConfig] = [
      TextOverlayConfig(
        superTitle: .init(
          string: "This is an example of how a training can be exported as a pretty video clip.",
          attributes: superTitleAttributes
        ),
        title: .init(string: "Side plank", attributes: titleAttributes),
        bodyLines: [.init(string: "Time 40", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
      TextOverlayConfig(
        title: .init(string: "Pistol sit-ups", attributes: titleAttributes),
        bodyLines: [.init(string: "Reps 10", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
      TextOverlayConfig(
        title: .init(string: "Plain sit-ups", attributes: titleAttributes),
        bodyLines: [.init(string: "Reps 10", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
      TextOverlayConfig(
        title: .init(string: "Push-ups", attributes: titleAttributes),
        bodyLines: [.init(string: "Reps 20", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
      TextOverlayConfig(
        title: .init(string: "Pull-ups", attributes: titleAttributes),
        bodyLines: [.init(string: "Reps 7", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
    ]
    self.dataContext = .init(
      media: [
        "https://juiceapp.cc/storage/videos/2936/KqpwfYBMN72J8CYVDhM1Q4UU4RtNSf.mp4",
        "https://juiceapp.cc/storage/videos/2936/praQXLAzWG4xCKMn7bi75glvrSbuYT.mp4",
        //      "https://juiceapp.cc/storage/videos/2936/BS1lFFZUa4j6nfES6WsZ2mgJr9LtgL.mp4",
        //      "https://juiceapp.cc/storage/videos/2936/13rb3QPu5tyhqRNyd5PuEMOa6FD8LW.mp4",
        //      "https://juiceapp.cc/storage/videos/2936/sxS9mSHqPQFj9KFlNcLxwLZj5jmQJq.mp4"
      ],
      textOverlays: texts
    )
    super.init(coder: coder)
  }
  // MARK: - Essentials
  private let editor = ClipMaker()

  private let composerQueue = DispatchQueue(label: "video.composing.queue", attributes: .concurrent)
  private let videoEditorQueue = DispatchQueue(label: "video.editor.queue", attributes: .concurrent)

  // MARK: - UI
  private var player: AVPlayer?
  private var layer: AVPlayerLayer?
  lazy private var videoView: UIView = {
    let view = UIView(
      frame: .init(origin: .zero,
                   size: .init(width: self.view.bounds.width,
                               height: self.view.bounds.width * 0.667)
      )
    )
    view.backgroundColor = UIColor.lightGray
    return view
  }()

  lazy private var generateButton: UIButton = UIButton(frame: .zero)

  lazy private var actionButton = ActionButton(self.actionButtonConfig)

  // MARK: - Life cycle
  override public func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.videoView.center = self.view.center
    self.view.addSubview(self.videoView)
    self.view.addSubview(self.actionButton)
    self.setupLayout()
    self.generateButton.addTarget(self, action: #selector(self.didTapActionButton), for: .touchUpInside)
    self.actionButton.tapHandler = { [weak self] in
      self?.generateVideo()
    }
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .save,
      target: self,
      action: #selector(self.didTapSave)
    )
  }

  // MARK: - Actions
  @objc
  private func didTapActionButton() {
    #if targetEnvironment(simulator)
    let alert = UIAlertController(
      title: "Oops!",
      message: "This can't be run on a simulator! Use your device instead.",
      preferredStyle: .alert
    )

    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)

    alert.addAction(okAction)

    self.present(alert, animated: true, completion: nil)
    #else
    self.generateVideo()
    #endif
  }

  @objc
  private func didTapSave() {
    guard let url = currentItemURL else {
      let alert = UIAlertController(
        title: "Nothing to save!",
        message: "Press generate and wait for a video to appear.",
        preferredStyle: .alert
      )
      let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
      alert.addAction(ok)
      self.present(alert, animated: true, completion: nil)
      return
    }
    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
    }) { saved, error in
      if saved {
        debugPrint("video has been saved to gallery")
      }
    }
  }

  var currentItemURL: URL?
}

private extension ClipMakerController {

  func enterPendingState() {
    self.actionButton.enterPendingState()
  }

  func exitPendingState() {
    self.actionButton.exitPendingState()
  }

  func generateVideo() {
    self.enterPendingState()
    self.composerQueue.async {

      let videos = zip(self.dataContext.media.compactMap { URL(string: $0) }, self.dataContext.textOverlays)
        .map { self.processVideo(
          at: $0.0,
          textOverlay: $0.1,
          on: self.videoEditorQueue) }

      self.editor.mergeVideos(urls: videos) { result in
        switch result {
        case .success(let exportedURL):
          self.currentItemURL = exportedURL
          DispatchQueue.main.async {
            self.showVideo(url: exportedURL)
            self.exitPendingState()
          }
        case .failure(let error):
          print(error)
          DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error!", message: error.localizedDescription, preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            self.exitPendingState()
          }
        }
      }
    }
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

  func setupLayout() {
    self.actionButton.translatesAutoresizingMaskIntoConstraints = false
    self.actionButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    self.actionButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
    self.actionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    self.actionButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true
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

  func showVideo(url: URL) {
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
}
