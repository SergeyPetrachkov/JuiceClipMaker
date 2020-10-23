//
//  ClipMakerViewModel.swift
//  JuiceClipMaker
//
//  Created by sergey on 21.10.2020.
//

import AVKit
import Foundation
import Photos

public protocol ClipMakerViewModelOutput: AnyObject {
  func didChangeState(_ state: ClipMakerViewModel.State)
  var viewContext: UIViewController? { get }
}

public final class ClipMakerViewModel {
  public enum Errors: Swift.Error {
    case noVideo
  }
  public enum State {
    case initial(URL?)
    case generating
    case generated(URL)
    case saving
    case saved
    case failed(Error)
  }
  // MARK: - Connectors
  public var didStartMakingVideo: (() -> Void)?
  public var didFinishMakingVideo: ((Result<URL, Error>) -> Void)?
  public var didSaveVideo: (() -> Void)?
  public var didFailToSaveVideo: (() -> Void)?
  public var didFinishFlow: (() -> Void)?

  public weak var output: ClipMakerViewModelOutput? {
    didSet {
      self.output?.didChangeState(self.state)
    }
  }
  // MARK: - Context
  private let dataContext: ClipMakerContext
  private var currentUrl: URL?
  private(set) var state: State {
    didSet {
      self.output?.didChangeState(self.state)
    }
  }
  // MARK: - Essentials
  private let editor = ClipMaker()

  private let composerQueue = DispatchQueue(label: "video.composing.queue", attributes: .concurrent)
  private let videoEditorQueue = DispatchQueue(label: "video.editor.queue", attributes: .concurrent)

  private let shouldStartRightAway: Bool

  // MARK: - Initializers
  public init(dataContext: ClipMakerContext, startRightAway: Bool) {
    self.dataContext = dataContext
    self.shouldStartRightAway = startRightAway
    if let placeholder = self.dataContext.placeholder {
      let url = URL(string: placeholder)
      self.state = .initial(url)
    } else {
      self.state = .initial(nil)
    }
  }

  func start() {
    if self.shouldStartRightAway {
      self.generateVideo()
    }
  }

  func stop() {
    
  }

  public func primaryAction() {
    switch state {
    case .initial, .failed:
      self.generateVideo()
    case .generated(let url):
      self.shareVideo(url: url)
    case .generating, .saving, .saved:
      break
    }
  }

  public func secondaryAction() {
    self.saveVideo()
  }

  public func generateVideo() {
    self.state = .generating
    self.didStartMakingVideo?()
    self.composerQueue.async {

      let videos = zip(self.dataContext.media.compactMap { URL(string: $0) }, self.dataContext.textOverlays)
        .map {
          self.processVideo(
            at: $0.0,
            textOverlay: $0.1,
            on: self.videoEditorQueue
          )
        }

      self.editor.mergeVideos(urls: videos) { [weak self] result in
        guard let self = self else { return }
        switch result {
        case .success(let url):
          if self.cancelled {
            self.deleteVideo(url: url)
            return
          }
          self.state = .generated(url)
        case .failure(let error):
          self.state = .failed(error)
        }
        if self.cancelled {
          NSLog("Cancelled clip maker")
        } else {
          self.didFinishMakingVideo?(result)
        }
      }
    }
  }

  private var cancelled: Bool = false
  public func close() {
    self.cancelled = true
    self.didFinishFlow?()
  }

  public func saveVideo() {

    guard case State.generated(let url) = self.state else {
      return
    }
    self.state = .saving
    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
    }) { saved, error in
      if let error = error {
        self.didFailToSaveVideo?()
        self.state = .failed(error)
      } else {
        self.didSaveVideo?()
        self.state = .saved
      }
    }
  }

  private func shareVideo(url: URL) {
    guard let viewContext = self.output?.viewContext else {
      return
    }
    let sharingVC = UIActivityViewController(activityItems: [url], applicationActivities: [])

    sharingVC.completionWithItemsHandler = { [weak self] _,_,_,_ in
      self?.didFinishFlow?()
    }

    viewContext.present(sharingVC, animated: true, completion: nil)
  }

  private func processVideo(at url: URL, textOverlay: TextOverlayConfig, on queue: DispatchQueue) -> URL {
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

  private func deleteVideo(url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
