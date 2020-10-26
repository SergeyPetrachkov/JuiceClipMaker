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
    self.viewModel = ClipMakerViewModel(dataContext: dataContext, startRightAway: false, saveIntermediateVideos: false)
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
      secondaryActionConfig: .init(buttonTitle: "Save to gallery"),
      shareActionConfig: .init(buttonTitle: "Share")
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
      placeholder: "https://juiceapp.cc/storage/videos/2936/KqpwfYBMN72J8CYVDhM1Q4UU4RtNSf.jpg",
      media: [
        "https://juiceapp.cc/storage/videos/2936/KqpwfYBMN72J8CYVDhM1Q4UU4RtNSf.mp4",
        "https://juiceapp.cc/storage/videos/2936/praQXLAzWG4xCKMn7bi75glvrSbuYT.mp4",
        //      "https://juiceapp.cc/storage/videos/2936/BS1lFFZUa4j6nfES6WsZ2mgJr9LtgL.mp4",
        //      "https://juiceapp.cc/storage/videos/2936/13rb3QPu5tyhqRNyd5PuEMOa6FD8LW.mp4",
        //      "https://juiceapp.cc/storage/videos/2936/sxS9mSHqPQFj9KFlNcLxwLZj5jmQJq.mp4"
      ],
      textOverlays: texts
    )
    self.viewModel = .init(dataContext: dataContext, startRightAway: false, saveIntermediateVideos: false)
    super.init(coder: coder)
  }

  // MARK: - UI
  private var player: AVPlayer?
  private var layer: AVPlayerLayer?
  lazy private var videoView: UIImageView = {
    let view = UIImageView(frame: .zero)
    view.backgroundColor = UIColor.lightGray
    view.contentMode = .scaleAspectFit
    return view
  }()

  lazy private var actionButton = ActionButton(self.actionButtonConfig)

  private var line: UIView = UIView(frame: .zero)

  lazy private var secondaryActionButton = ActionButton(self.secondaryActionButtonConfig)

  lazy var activityIndicator: UIActivityIndicatorView = {
    let style: UIActivityIndicatorView.Style = .whiteLarge
    let view = UIActivityIndicatorView(style: style)
    return view
  }()

  // MARK: - Life cycle
  override public func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .white
    self.view.addSubview(self.videoView)
    self.view.addSubview(self.actionButton)
    self.view.addSubview(self.line)
    self.view.addSubview(self.secondaryActionButton)
    self.setupLayout()

    self.actionButton.tapHandler = { [weak self] in
      self?.viewModel.primaryAction()
    }
    self.secondaryActionButton.tapHandler = { [weak self] in
      self?.viewModel.secondaryAction()
    }
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .save,
      target: self,
      action: #selector(self.didTapSave)
    )
    self.viewModel.start()
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
    self.videoView.addSubview(self.activityIndicator)
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    self.activityIndicator.centerXAnchor.constraint(equalTo: self.videoView.centerXAnchor).isActive = true
    self.activityIndicator.centerYAnchor.constraint(equalTo: self.videoView.centerYAnchor).isActive = true
    self.activityIndicator.startAnimating()
  }

  func exitPendingState() {
    self.actionButton.exitPendingState()
    self.activityIndicator.stopAnimating()
    self.activityIndicator.removeFromSuperview()
  }

  func setupLayout() {
    self.line.backgroundColor = UIColor(red: 224.0/255, green: 224.0/255, blue: 224.0/255, alpha: 1)

    self.videoView.translatesAutoresizingMaskIntoConstraints = false
    self.videoView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    self.videoView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
    self.videoView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.667).isActive = true
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
    case .initial(let url):
      guard let url = url else {
        return
      }
      self.videoView.load(url: url)
    case .generating:
      self.title = "Generating video..."
      self.enterPendingState()
      self.actionButton.setup(with: self.uiConfig.shareActionConfig)
      self.actionButton.disable()
      self.secondaryActionButton.disable()
    case .generated(let url):
      self.showVideo(url: url)
      self.actionButton.enable()
      self.secondaryActionButton.enable()
    case .saving:
      self.actionButton.disable()
      self.secondaryActionButton.disable()
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
      self.actionButton.enable()
      self.secondaryActionButton.enable()
    }
  }

  public weak var viewContext: UIViewController? {
    return self
  }
}

private extension UIImageView {
  func load(url: URL) {
    DispatchQueue.global().async { [weak self] in
      if let data = try? Data(contentsOf: url) {
        if let image = UIImage(data: data) {
          DispatchQueue.main.async {
            self?.image = image
          }
        }
      }
    }
  }
}
