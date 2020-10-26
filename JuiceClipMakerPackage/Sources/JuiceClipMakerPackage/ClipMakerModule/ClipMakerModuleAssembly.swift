//
//  ClipMakerModuleAssembly.swift
//  JuiceClipMaker
//
//  Created by sergey on 20.10.2020.
//

import Foundation

public enum ClipMakerModuleAssembly {

  public typealias ClipMakerModule = (view: ClipMakerController, viewModel: ClipMakerViewModel)

  public static func createModule(
    uiConfig: ClipMakerUIConfig,
    dataContext: ClipMakerContext,
    startRightAway: Bool = true,
    saveIntermediateVideos: Bool = false
  ) -> ClipMakerModule {
    let viewModel = ClipMakerViewModel(dataContext: dataContext,
                                       startRightAway: startRightAway,
                                       saveIntermediateVideos: saveIntermediateVideos)
    let view = ClipMakerController(uiConfig: uiConfig, viewModel: viewModel)
    viewModel.output = view
    return (view: view, viewModel: viewModel)
  }
}
