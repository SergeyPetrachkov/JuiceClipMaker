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
}

public final class ClipMakerViewModel {
  public enum Errors: Swift.Error {
    case noVideo
  }
  public enum State {
    case initial
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

  public weak var output: ClipMakerViewModelOutput? {
    didSet {
      self.output?.didChangeState(self.state)
    }
  }
  // MARK: - Context
  private let dataContext: ClipMakerContext
  private var currentUrl: URL?
  private(set) var state: State = .initial {
    didSet {
      self.output?.didChangeState(self.state)
    }
  }
  // MARK: - Essentials
  private let editor = ClipMaker()

  private let composerQueue = DispatchQueue(label: "video.composing.queue", attributes: .concurrent)
  private let videoEditorQueue = DispatchQueue(label: "video.editor.queue", attributes: .concurrent)

  // MARK: - Initializers
  public init(dataContext: ClipMakerContext) {
    self.dataContext = dataContext
  }

  public func primaryAction() {

  }

  public func secondaryAction() {

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
        switch result {
        case .success(let url):
          self?.state = .generated(url)
        case .failure(let error):
          self?.state = .failed(error)
        }
        self?.didFinishMakingVideo?(result)
      }
    }
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
}
