//
//  ClipMakerContext.swift
//  JuiceClipMaker
//
//  Created by sergey on 20.10.2020.
//

import Foundation

public struct ClipMakerContext {

  public typealias MediaPath = String

  public let media: [MediaPath]
  public let textOverlays: [TextOverlayConfig]

  public init(media: [MediaPath], textOverlays: [TextOverlayConfig]) {
    self.media = media
    self.textOverlays = textOverlays
  }
}
