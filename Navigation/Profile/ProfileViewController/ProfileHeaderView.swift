//
//  ProfileHeaderView.swift
//  Navigation
//
//  Created by Egor Badaev on 05.11.2020.
//  Copyright © 2020 Artem Novichkov. All rights reserved.
//

import UIKit

class ProfileHeaderView: UIView {

    // MARK: - Constants

    private enum Config {
        static let largeMargin: CGFloat = 27.0
        static let cornerRadius: CGFloat = 12.0
        static let shadowOffset: CGFloat = 4.0
        static let avatarSize: CGFloat = 110.0
        static let textFieldHeight: CGFloat = 40.0
        static let statusButtonHeight: CGFloat = 50.0
        static let defaultStatusText = "Waiting for something..."
    }
    
    var logoutCompletion: (() -> Void)?

    // MARK: - Setup UI

    let avatarContainerView: UIView = {
        let containerView = UIView()
        containerView.toAutoLayout()
        return containerView
    }()

    lazy var avatarImageView: UIImageView = {
        let avatarImageView = UIImageView()

        avatarImageView.toAutoLayout()
        avatarImageView.image = #imageLiteral(resourceName: "profilePhoto")
        avatarImageView.layer.cornerRadius = Config.avatarSize / 2
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.clipsToBounds = true

        return avatarImageView
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()

        titleLabel.toAutoLayout()
        titleLabel.text = "John Appleseed"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        if #available(iOS 13.0, *) {
            titleLabel.textColor = .label
        } else {
            titleLabel.textColor = .black
        }
        titleLabel.sizeToFit()

        return titleLabel
    }()
    
    private lazy var logoutButton: UIButton = {
        let logoutButton = UIButton(type: .system)
        
        logoutButton.toAutoLayout()
        logoutButton.setTitle("Sign out", for: .normal)
        logoutButton.titleLabel?.textAlignment = .left
        logoutButton.addTarget(self, action: #selector(logOutButtonTapped(_:)), for: .touchUpInside)
        
        return logoutButton
    }()

    private lazy var statusLabel: UILabel = {
        let statusLabel = UILabel()

        statusLabel.toAutoLayout()
        statusLabel.text = Config.defaultStatusText
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        if #available(iOS 13.0, *) {
            statusLabel.textColor = .secondaryLabel
        } else {
            statusLabel.textColor = .gray
        }
        statusLabel.sizeToFit()

        return statusLabel

    }()

    private lazy var statusButton: UIButton = {
        let statusButton = UIButton(type: .system)

        statusButton.toAutoLayout()
        statusButton.backgroundColor = .systemBlue
        statusButton.setTitleColor(.white, for: .normal)
        statusButton.setTitle("Set status", for: .normal)
        statusButton.clipsToBounds = true
        statusButton.layer.masksToBounds = false
        statusButton.layer.cornerRadius = Config.cornerRadius
        statusButton.layer.shadowOffset = CGSize(width: Config.shadowOffset, height: Config.shadowOffset)
        statusButton.layer.shadowRadius = Config.shadowOffset * 2
        statusButton.layer.shadowColor = UIColor.black.cgColor
        statusButton.layer.shadowOpacity = 0.4
        statusButton.addTarget(self, action: #selector(statusButtonTapped(_:)), for: .touchUpInside)

        return statusButton
    }()

    private lazy var statusTextField: StatusTextField = {
        let statusTextField = StatusTextField()

        statusTextField.toAutoLayout()
        if #available(iOS 13.0, *) {
            statusTextField.textColor = .label
        } else {
            statusTextField.textColor = .black
        }
        statusTextField.font = UIFont.systemFont(ofSize: 15.0)
        statusTextField.placeholder = "Set your status..."
        statusTextField.layer.masksToBounds = true
        statusTextField.layer.addSublayer(statusTextFieldBackgroundLayer)

        statusTextField.addTarget(self, action: #selector(statusTextFieldChanged(_:)), for: .editingChanged)

        return statusTextField
    }()

    private let statusTextFieldBackgroundLayer: CALayer = {

        let statusTextFieldBackgroundLayer = CALayer()
        
        statusTextFieldBackgroundLayer.masksToBounds = true
        statusTextFieldBackgroundLayer.borderWidth = 1.0
        statusTextFieldBackgroundLayer.cornerRadius = Config.cornerRadius
        if #available(iOS 13.0, *) {
            statusTextFieldBackgroundLayer.borderColor = UIColor.label.cgColor
            statusTextFieldBackgroundLayer.backgroundColor = UIColor.systemBackground.cgColor
        } else {
            statusTextFieldBackgroundLayer.borderColor = UIColor.black.cgColor
            statusTextFieldBackgroundLayer.backgroundColor = UIColor.white.cgColor
        }

        return statusTextFieldBackgroundLayer
    }()
    
    private lazy var statusText: String = Config.defaultStatusText

    var avatarConstraints: [NSLayoutConstraint] = []

    // MARK: - Life cycle

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        statusTextFieldBackgroundLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: statusTextField.bounds.width,
            height: statusTextField.bounds.height
        )

        statusButton.layer.shadowPath = UIBezierPath(roundedRect: statusButton.bounds, cornerRadius: Config.cornerRadius).cgPath

    }

    // MARK: - Private methods

    private func setupUI() {

        if #available(iOS 13.0, *) {
            backgroundColor = .systemGray6
        } else {
            backgroundColor = .lightGray
        }

        addSubview(avatarContainerView)
        avatarContainerView.addSubview(avatarImageView)
        addSubview(titleLabel)
        addSubview(logoutButton)
        addSubview(statusLabel)
        addSubview(statusTextField)
        addSubview(statusButton)

        let constraints = [
            avatarContainerView.topAnchor.constraint(equalTo: topAnchor, constant: AppConstants.margin),
            avatarContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppConstants.margin),
            avatarContainerView.heightAnchor.constraint(equalToConstant: Config.avatarSize),
            avatarContainerView.widthAnchor.constraint(equalTo: avatarContainerView.heightAnchor),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Config.largeMargin),
            titleLabel.leadingAnchor.constraint(equalTo: avatarContainerView.trailingAnchor, constant: AppConstants.margin),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppConstants.margin),
            
            logoutButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            logoutButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            statusButton.topAnchor.constraint(equalTo: avatarContainerView.bottomAnchor, constant: 43.0),
            statusButton.leadingAnchor.constraint(equalTo: avatarContainerView.leadingAnchor),
            statusButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            statusButton.heightAnchor.constraint(equalToConstant: Config.statusButtonHeight),
            statusButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AppConstants.margin),

            statusTextField.bottomAnchor.constraint(equalTo: statusButton.topAnchor, constant: -AppConstants.margin),
            statusTextField.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusTextField.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            statusTextField.heightAnchor.constraint(equalToConstant: Config.textFieldHeight),

            statusLabel.bottomAnchor.constraint(equalTo: statusTextField.topAnchor, constant: -6.0),
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ]

        avatarConstraints = [
            avatarImageView.topAnchor.constraint(equalTo: avatarContainerView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainerView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarContainerView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainerView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
        NSLayoutConstraint.activate(avatarConstraints)

    }

    @objc private func statusButtonTapped(_ sender: Any) {
        statusLabel.text = statusText

        // Очистить текстовое поле после установки статуса
        statusTextField.text = ""
    }

    @objc private func statusTextFieldChanged(_ sender: Any) {
        guard let textField = sender as? StatusTextField,
              let statusText = textField.text else {
            print("No status has been entered!")
            return
        }
        self.statusText = statusText
    }
    
    @objc private func logOutButtonTapped(_ sender: UIButton) {
        logoutCompletion?()
    }

}
