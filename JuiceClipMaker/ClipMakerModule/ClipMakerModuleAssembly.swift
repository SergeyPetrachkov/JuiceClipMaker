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
  ) -> (view: ClipMakerController, viewModel: ClipMakerViewModel) {
    let viewModel = ClipMakerViewModel(dataContext: dataContext)
    let view = ClipMakerController(actionButtonConfig: actionButtonConfig, viewModel: viewModel)
    return (view: view, viewModel: viewModel)
  }
}
