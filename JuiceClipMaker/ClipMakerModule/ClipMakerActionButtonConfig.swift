//
//  ClipMakerActionButtonConfig.swift
//  JuiceClipMaker
//
//  Created by sergey on 20.10.2020.
//

import UIKit

public struct TitleConfig {
  public let savingTitle: String
  public let generatingTitle: String
  public let generatedTitle: String

  public init(savingTitle: String, generatingTitle: String, generatedTitle: String) {
    self.savingTitle = savingTitle
    self.generatingTitle = generatingTitle
    self.generatedTitle = generatedTitle
  }
}

public struct ClipMakerActionButtonConfig {
  
  public let buttonBackground: UIColor
  public let buttonTitle: String
  public let buttonTitleColor: UIColor
  public let buttonWidthRatio: Double
  public let buttonHeight: Double
  public let cornerRadius: CGFloat

  public init(
    buttonBackground: UIColor = UIColor.clear,
    buttonTitle: String = "Generate",
    buttonTitleColor: UIColor = UIColor(red: 85.0/255, green: 153.0/255, blue: 236.0/255, alpha: 1),
    buttonWidthRatio: Double = 0.8,
    buttonHeight: Double = 50,
    cornerRadius: CGFloat = 0
  ) {
    self.buttonBackground = buttonBackground
    self.buttonTitle = buttonTitle
    self.buttonTitleColor = buttonTitleColor
    self.buttonWidthRatio = buttonWidthRatio
    self.buttonHeight = buttonHeight
    self.cornerRadius = cornerRadius
  }
}

public struct ClipMakerUIConfig {
  let titleConfig: TitleConfig
  let primaryActionConfig: ClipMakerActionButtonConfig
  let secondaryActionConfig: ClipMakerActionButtonConfig
}
