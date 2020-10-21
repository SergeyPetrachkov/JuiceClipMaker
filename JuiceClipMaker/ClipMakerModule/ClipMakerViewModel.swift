//
//  ClipMakerViewModel.swift
//  JuiceClipMaker
//
//  Created by sergey on 21.10.2020.
//

import AVKit
import Foundation
import Photos

public final class ClipMakerViewModel {
  // MARK: - Connectors
  public var didStartMakingVideo: (() -> Void)?
  public var didFinishMakingVideo: ((Result<URL, Error>) -> Void)?
  public var didSaveVideo: (() -> Void)?
  public var didFailToSaveVideo: (() -> Void)?
  // MARK: - Context
  private let dataContext: ClipMakerContext
  private var currentUrl: URL?
  // MARK: - Essentials
  private let editor = ClipMaker()

  private let composerQueue = DispatchQueue(label: "video.composing.queue", attributes: .concurrent)
  private let videoEditorQueue = DispatchQueue(label: "video.editor.queue", attributes: .concurrent)

  // MARK: - Initializers
  public init(dataContext: ClipMakerContext) {
    self.dataContext = dataContext
  }

  public func generateVideo() {
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
        self?.didFinishMakingVideo?(result)
      }
    }
  }

  public func saveVideo() {
    guard let url = self.currentUrl else {
      self.didFailToSaveVideo?()
      return
    }

    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
    }) { saved, error in
      if error != nil {
        self.didFailToSaveVideo?()
      } else {
        self.didSaveVideo?()
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
