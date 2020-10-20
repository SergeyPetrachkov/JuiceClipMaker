//
//  ClipMakerActionButtonConfig.swift
//  JuiceClipMaker
//
//  Created by sergey on 20.10.2020.
//

import UIKit

public struct ClipMakerActionButtonConfig {
  public init(
    buttonBackground: UIColor = UIColor(red: 85.0/255, green: 153.0/255, blue: 236.0/255, alpha: 1),
    buttonTitle: String = "Generate",
    buttonWidthRatio: Double = 0.8,
    buttonHeight: Double = 50
  ) {
    self.buttonBackground = buttonBackground
    self.buttonTitle = buttonTitle
    self.buttonWidthRatio = buttonWidthRatio
    self.buttonHeight = buttonHeight
  }

  public let buttonBackground: UIColor
  public let buttonTitle: String
  public let buttonWidthRatio: Double
  public let buttonHeight: Double
}
