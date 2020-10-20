//
//  ActionButton.swift
//  JuiceClipMaker
//
//  Created by sergey on 20.10.2020.
//

import UIKit

final class ActionButton: UIButton {

  let config: ClipMakerActionButtonConfig
  var tapHandler: (() -> Void)? = nil

  lazy var activityIndicator: UIActivityIndicatorView = {
    let style: UIActivityIndicatorView.Style = self.config.buttonBackground == .white || self.config.buttonBackground == .clear ? .gray : .white
    let view = UIActivityIndicatorView(style: style)
    return view
  }()

  init(_ config: ClipMakerActionButtonConfig) {
    self.config = config
    super.init(frame: .zero)
    self.addTarget(self, action: #selector(self.didTapSelf), for: .touchUpInside)
    self.layer.cornerRadius = 10
    self.clipsToBounds = true
    self.setTitle(self.config.buttonTitle, for: .normal)
    self.setBackgroundImage(UIImage.from(color: self.config.buttonBackground), for: .normal)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc
  private func didTapSelf() {
    self.tapHandler?()
  }

  func enterPendingState() {
    self.isUserInteractionEnabled = false
    self.titleLabel?.alpha = 0

    DispatchQueue.main.async {
      self.activityIndicator.frame.origin = CGPoint(x: self.bounds.width/2 - (self.activityIndicator.frame.width) / 2,
                                                    y: self.bounds.height/2 - (self.activityIndicator.frame.height) / 2)

      self.addSubview(self.activityIndicator)
      self.activityIndicator.startAnimating()
    }
  }

  func exitPendingState() {
    self.isUserInteractionEnabled = true
    self.titleLabel?.alpha = 1
    DispatchQueue.main.async {
      self.activityIndicator.stopAnimating()
      self.activityIndicator.removeFromSuperview()
    }
  }
}
