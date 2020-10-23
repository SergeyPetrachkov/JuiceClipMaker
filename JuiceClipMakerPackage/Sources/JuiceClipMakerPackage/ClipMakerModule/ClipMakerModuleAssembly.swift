//
//  ClipMakerModuleAssembly.swift
//  JuiceClipMaker
//
//  Created by sergey on 20.10.2020.
//

import Foundation

public enum ClipMakerModuleAssembly {

  public static func createModule(
    uiConfig: ClipMakerUIConfig,
    dataContext: ClipMakerContext,
    startRightAway: Bool = true
  ) -> (view: ClipMakerController, viewModel: ClipMakerViewModel) {
    let viewModel = ClipMakerViewModel(dataContext: dataContext, startRightAway: startRightAway)
    let view = ClipMakerController(uiConfig: uiConfig, viewModel: viewModel)
    viewModel.output = view
    return (view: view, viewModel: viewModel)
  }
}
