//
//  ClipMakerModuleAssembly.swift
//  JuiceClipMaker
//
//  Created by sergey on 20.10.2020.
//

import Foundation

public enum ClipMakerModuleAssembly {
  public static func createModule(
    actionButtonConfig: ClipMakerActionButtonConfig,
    dataContext: ClipMakerContext
  ) -> ClipMakerController {
    return ClipMakerController(actionButtonConfig: actionButtonConfig, dataContext: dataContext)
  }
}
