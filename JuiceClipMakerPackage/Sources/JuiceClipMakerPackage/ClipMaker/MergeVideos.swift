//
//  MergeVideos.swift
//  JuiceClipMaker
//
//  Created by sergey on 10.10.2020.
//

import Foundation
import AVKit

/// Method to merge multiple videos
///
/// - Parameters:
///   - videoURLs: the videos to merge URLs
///   - fileName: the name of the finished merged video file
///   - completion: either url to the resulting video or a failure reason as an Error
func mergeMovies(videoURLs: [URL], filename: String = UUID().uuidString, completion: @escaping (Result<URL, Error>) -> Void) {
  let acceptableVideoExtensions = ["mov", "mp4", "m4v"]
  let _videoURLs = videoURLs.filter({ !$0.absoluteString.contains(".DS_Store") && acceptableVideoExtensions.contains($0.pathExtension.lowercased()) })

  /// guard against missing URLs
  guard !_videoURLs.isEmpty else {
    DispatchQueue.main.async {
      completion(.failure(Errors.assetError))
    }
    return
  }

  var videoAssets: [AVURLAsset] = []
  var completeMoviePath: URL?

  for path in _videoURLs {
    if let _url = URL(string: path.absoluteString) {
      videoAssets.append(AVURLAsset(url: _url))
    }
  }

  if let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
    completeMoviePath = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(filename).mp4")

    if let completeMoviePath = completeMoviePath {
      if FileManager.default.fileExists(atPath: completeMoviePath.path) {
        do {
          /// delete an old duplicate file
          try FileManager.default.removeItem(at: completeMoviePath)
        } catch {
          DispatchQueue.main.async {
            completion(.failure(error))
          }
        }
      }
    }
  } else {
    DispatchQueue.main.async {
      completion(.failure(Errors.exportError))
    }
  }

  let composition = AVMutableComposition()

  if let completeMoviePath = completeMoviePath {

    /// add audio and video tracks to the composition
    if let videoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid), let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) {

      var insertTime = CMTime(seconds: 0, preferredTimescale: 1)

      /// for each URL add the video and audio tracks and their duration to the composition
      for sourceAsset in videoAssets {
        do {
          if let assetVideoTrack = sourceAsset.tracks(withMediaType: .video).first, let assetAudioTrack = sourceAsset.tracks(withMediaType: .audio).first {
            let frameRange = CMTimeRange(start: CMTime(seconds: 0, preferredTimescale: 1), duration: sourceAsset.duration)
            try videoTrack.insertTimeRange(frameRange, of: assetVideoTrack, at: insertTime)
            try audioTrack.insertTimeRange(frameRange, of: assetAudioTrack, at: insertTime)

            videoTrack.preferredTransform = assetVideoTrack.preferredTransform
          }

          insertTime = insertTime + sourceAsset.duration
        } catch {
          DispatchQueue.main.async {
            completion(.failure(error))
          }
        }
      }

      /// try to start an export session and set the path and file type
      if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) {
        exportSession.outputURL = completeMoviePath
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true

        /// try to export the file and handle the status cases
        exportSession.exportAsynchronously(completionHandler: {
          switch exportSession.status {
          case .failed:
            if let _error = exportSession.error {
              DispatchQueue.main.async {
                completion(.failure(_error))
              }
            }

          case .cancelled:
            if let _error = exportSession.error {
              DispatchQueue.main.async {
                completion(.failure(_error))
              }
            }

          default:
            print("finished")
            DispatchQueue.main.async {
              completion(.success(completeMoviePath))
            }
          }
        })
      } else {
        DispatchQueue.main.async {
          completion(.failure(Errors.exportSessionCreationError))
        }
      }
    }
  }
}
