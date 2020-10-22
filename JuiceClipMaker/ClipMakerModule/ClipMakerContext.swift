//
//  ClipMakerContext.swift
//  JuiceClipMaker
//
//  Created by sergey on 20.10.2020.
//

import Foundation

public struct ClipMakerContext {

  public typealias MediaPath = String

  public let placeholder: MediaPath?

  public let media: [MediaPath]
  public let textOverlays: [TextOverlayConfig]

  public init(placeholder: MediaPath?, media: [MediaPath], textOverlays: [TextOverlayConfig]) {
    self.placeholder = placeholder
    self.media = media
    self.textOverlays = textOverlays
  }
}
