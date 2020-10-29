//
//  ActionButton.swift
//  JuiceClipMaker
//
//  Created by sergey on 20.10.2020.
//

import UIKit

final class ActionButton: UIButton {

  private(set) var config: ClipMakerActionButtonConfig
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
    self.clipsToBounds = true
    self.setup(with: config)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func setup(with config: ClipMakerActionButtonConfig) {
    self.layer.cornerRadius = config.cornerRadius
    self.setTitle(config.buttonTitle, for: .normal)
    self.setTitleColor(config.buttonTitleColor, for: .normal)
    self.setTitleColor(UIColor(red: 218.0/255,
                               green: 218.0/255,
                               blue: 218.0/255,
                               alpha: 1),
                       for: .disabled)
    self.setBackgroundImage(UIImage.from(color: config.buttonBackground), for: .normal)
    self.config = config
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

  func disable() {
    self.isEnabled = false
  }

  func enable() {
    self.isEnabled = true
  }
}

extension UIColor {
  var inverted: UIColor {
    var a: CGFloat = 0.0, r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
    return getRed(&r, green: &g, blue: &b, alpha: &a) ? UIColor(red: 1.0-r, green: 1.0-g, blue: 1.0-b, alpha: a) : .black
  }
}
