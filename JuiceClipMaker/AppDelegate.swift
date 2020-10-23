//
//  AppDelegate.swift
//  JuiceClipMaker
//
//  Created by sergey on 09.10.2020.
//

import UIKit
import JuiceClipMakerPackage

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    let window = UIWindow()
    let superTitleAttributes: TextOverlayConfig.TextAttributes = [
      .font: UIFont.systemFont(ofSize: 40),
      .foregroundColor: UIColor.white,
      .strokeColor: UIColor.white,
      .strokeWidth: -3,
    ]

    let titleAttributes: TextOverlayConfig.TextAttributes = [
      .font: UIFont.systemFont(ofSize: 35),
      .foregroundColor: UIColor.white,
      .strokeColor: UIColor.white,
      .strokeWidth: -3,
    ]

    let bodyAttributes: TextOverlayConfig.TextAttributes = [
      .font: UIFont.italicSystemFont(ofSize: 20),
      .foregroundColor: UIColor.darkGray,
      .strokeColor: UIColor.darkGray,
      .strokeWidth: -3,
    ]

    let texts: [TextOverlayConfig] = [
      TextOverlayConfig(
        superTitle: .init(
          string: "This is an example of how a training can be exported as a pretty video clip.",
          attributes: superTitleAttributes
        ),
        title: .init(string: "Side plank", attributes: titleAttributes),
        bodyLines: [.init(string: "Time 40", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
      TextOverlayConfig(
        title: .init(string: "Pistol sit-ups", attributes: titleAttributes),
        bodyLines: [.init(string: "Reps 10", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
      TextOverlayConfig(
        title: .init(string: "Plain sit-ups", attributes: titleAttributes),
        bodyLines: [.init(string: "Reps 10", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
      TextOverlayConfig(
        title: .init(string: "Push-ups", attributes: titleAttributes),
        bodyLines: [.init(string: "Reps 20", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
      TextOverlayConfig(
        title: .init(string: "Pull-ups", attributes: titleAttributes),
        bodyLines: [.init(string: "Reps 7", attributes: bodyAttributes),
                    .init(string: "Sets 2", attributes: bodyAttributes)]
      ),
    ]
    let context = ClipMakerContext(
      placeholder: "https://juiceapp.cc/storage/videos/2936/KqpwfYBMN72J8CYVDhM1Q4UU4RtNSf.jpg",
      media: [
        "https://juiceapp.cc/storage/videos/2936/KqpwfYBMN72J8CYVDhM1Q4UU4RtNSf.mp4",
        "https://juiceapp.cc/storage/videos/2936/praQXLAzWG4xCKMn7bi75glvrSbuYT.mp4",
        "https://juiceapp.cc/storage/videos/2936/BS1lFFZUa4j6nfES6WsZ2mgJr9LtgL.mp4",
        "https://juiceapp.cc/storage/videos/2936/13rb3QPu5tyhqRNyd5PuEMOa6FD8LW.mp4",
        "https://juiceapp.cc/storage/videos/2936/sxS9mSHqPQFj9KFlNcLxwLZj5jmQJq.mp4"
      ],
      textOverlays: texts
    )
    let uiConfig = ClipMakerUIConfig(
      titleConfig: .init(savingTitle: "Saving", generatingTitle: "Generating video...", generatedTitle: "Your video is ready"),
      primaryActionConfig: .init(),
      secondaryActionConfig: .init(buttonTitle: "Save to gallery"),
      shareActionConfig: .init(buttonTitle: "Share")
    )
    let makerModule = ClipMakerModuleAssembly.createModule(uiConfig: uiConfig, dataContext: context)
    makerModule.view.title = "Clip Maker"
    window.rootViewController = makerModule.view
    window.makeKeyAndVisible()
    self.window = window
    return true
  }
}

