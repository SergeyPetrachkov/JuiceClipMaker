//
//  TextOverlay.swift
//  JuiceClipMaker
//
//  Created by sergey on 13.10.2020.
//

import Foundation

public struct TextOverlayConfig {

  public typealias TextAttributes = [NSAttributedString.Key: Any]

  public enum Position {
    case bottomLeft
    case topLeft
    case bottomRight
    case topRight
    case center
  }

  public let title: NSAttributedString
  public let bodyLines: [NSAttributedString]
  public let position: Position

  public init(title: NSAttributedString, bodyLines: [NSAttributedString], position: Position = .bottomLeft) {
    self.title = title
    self.bodyLines = bodyLines
    self.position = position
  }

  public init(title: String,
              titleAttributes: TextAttributes,
              bodyLines: [String],
              bodyAttributes: TextAttributes,
              position: Position = .bottomLeft) {
    self.title = NSAttributedString(string: title, attributes: titleAttributes)
    self.bodyLines = bodyLines.map { NSAttributedString(string: $0, attributes: bodyAttributes) }
    self.position = position
  }
}
