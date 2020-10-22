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
  private let uiConfig: ClipMakerUIConfig
  private var actionButtonConfig: ClipMakerActionButtonConfig {
    return self.uiConfig.primaryActionConfig
  }
  private var secondaryActionButtonConfig: ClipMakerActionButtonConfig {
    return self.uiConfig.secondaryActionConfig
  }

  let viewModel: ClipMakerViewModel
  // MARK: - Initializers
  public init(uiConfig: ClipMakerUIConfig, dataContext: ClipMakerContext) {
    self.uiConfig = uiConfig
    self.viewModel = ClipMakerViewModel(dataContext: dataContext)
    super.init(nibName: nil, bundle: nil)
  }

  public init(uiConfig: ClipMakerUIConfig, viewModel: ClipMakerViewModel) {
    self.uiConfig = uiConfig
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    self.uiConfig = .init(
      titleConfig: .init(savingTitle: "Saving", generatingTitle: "Generating video...", generatedTitle: "Your vide is ready"),
      primaryActionConfig: .init(),
      secondaryActionConfig: .init(buttonTitle: "Save to gallery")
    )
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
    let dataContext = ClipMakerContext(
      media: [
        "https://juiceapp.cc/storage/videos/2936/KqpwfYBMN72J8CYVDhM1Q4UU4RtNSf.mp4",
        "https://juiceapp.cc/storage/videos/2936/praQXLAzWG4xCKMn7bi75glvrSbuYT.mp4",
        //      "https://juiceapp.cc/storage/videos/2936/BS1lFFZUa4j6nfES6WsZ2mgJr9LtgL.mp4",
        //      "https://juiceapp.cc/storage/videos/2936/13rb3QPu5tyhqRNyd5PuEMOa6FD8LW.mp4",
        //      "https://juiceapp.cc/storage/videos/2936/sxS9mSHqPQFj9KFlNcLxwLZj5jmQJq.mp4"
      ],
      textOverlays: texts
    )
    self.viewModel = .init(dataContext: dataContext)
    super.init(coder: coder)
  }

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

  lazy private var actionButton = ActionButton(self.actionButtonConfig)

  private var line: UIView = UIView(frame: .zero)

  lazy private var secondaryActionButton = ActionButton(self.secondaryActionButtonConfig)

  // MARK: - Life cycle
  override public func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.videoView.center = self.view.center
    self.view.addSubview(self.videoView)
    self.view.addSubview(self.actionButton)
    self.view.addSubview(self.line)
    self.view.addSubview(self.secondaryActionButton)
    self.setupLayout()

    self.actionButton.tapHandler = { [weak self] in
      self?.viewModel.generateVideo()
    }
    self.secondaryActionButton.tapHandler = { [weak self] in
      self?.viewModel.secondaryAction()
    }
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .save,
      target: self,
      action: #selector(self.didTapSave)
    )

    self.viewModel.didStartMakingVideo = { [weak self] in
      self?.actionButton.enterPendingState()
    }

    self.viewModel.didFinishMakingVideo = { [weak self] result in
      guard let self = self else {
        return
      }
      switch result {
      case .success(let exportedURL):
        DispatchQueue.main.async {
          self.showVideo(url: exportedURL)
          self.actionButton.exitPendingState()
        }
      case .failure(let error):
        print(error)
        DispatchQueue.main.async {
          let alert = UIAlertController(title: "Error!", message: error.localizedDescription, preferredStyle: .alert)
          let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
          alert.addAction(ok)
          self.present(alert, animated: true, completion: nil)
          self.actionButton.exitPendingState()
        }
      }
    }

    self.viewModel.didSaveVideo = { [weak self] in

    }

    self.viewModel.didFailToSaveVideo = { [weak self] in
      guard let self = self else {
        return
      }
      let alert = UIAlertController(
        title: "Nothing to save!",
        message: "Press generate and wait for a video to appear.",
        preferredStyle: .alert
      )
      let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
      alert.addAction(ok)
      self.present(alert, animated: true, completion: nil)
    }
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
    self.viewModel.generateVideo()
    #endif
  }

  @objc
  private func didTapSave() {
    self.viewModel.saveVideo()
  }

  public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    return .portrait
  }

  public override var shouldAutorotate: Bool {
    return false
  }
}

private extension ClipMakerController {

  func enterPendingState() {

  }

  func exitPendingState() {
    self.actionButton.exitPendingState()
  }

  func setupLayout() {
    self.line.backgroundColor = UIColor(red: 224.0/255, green: 224.0/255, blue: 224.0/255, alpha: 1)

    self.videoView.translatesAutoresizingMaskIntoConstraints = false
    self.videoView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    self.videoView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
    self.videoView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.75).isActive = true
    self.videoView.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor, constant: 20).isActive = true

    self.actionButton.translatesAutoresizingMaskIntoConstraints = false
    self.actionButton.translatesAutoresizingMaskIntoConstraints = false
    self.actionButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    self.actionButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
    self.actionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    self.actionButton.topAnchor.constraint(equalTo: self.videoView.bottomAnchor, constant: 4).isActive = true

    self.line.translatesAutoresizingMaskIntoConstraints = false
    self.line.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
    self.line.heightAnchor.constraint(equalToConstant: 0.3).isActive = true
    self.line.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    self.line.topAnchor.constraint(equalTo: self.actionButton.bottomAnchor, constant: 0).isActive = true

    self.secondaryActionButton.translatesAutoresizingMaskIntoConstraints = false
    self.secondaryActionButton.translatesAutoresizingMaskIntoConstraints = false
    self.secondaryActionButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    self.secondaryActionButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
    self.secondaryActionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    self.secondaryActionButton.topAnchor.constraint(equalTo: self.line.bottomAnchor, constant: 0).isActive = true

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

extension ClipMakerController: ClipMakerViewModelOutput {
  public func didChangeState(_ state: ClipMakerViewModel.State) {
    switch state {
    case .initial:
      break
    case .generating:
      self.title = "Generating video..."
      break
    case .generated(let url):
      break
    case .saving:
      break
    case .saved:
      break
    case .failed(let error):
      let alert = UIAlertController(
        title: "Oops!",
        message: error.localizedDescription,
        preferredStyle: .alert
      )

      let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)

      alert.addAction(okAction)

      self.present(alert, animated: true, completion: nil)
    }
  }
}
