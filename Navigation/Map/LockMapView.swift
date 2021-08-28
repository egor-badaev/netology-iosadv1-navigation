//
//  LockMapView.swift
//  Navigation
//
//  Created by Egor Badaev on 28.08.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

class LockMapView: UIView {

    // MARK: - Properties

    private var buttonAction: (() -> Void)?

    private lazy var unavailableStack: UIStackView = {
        let unavailableStack = UIStackView()

        unavailableStack.toAutoLayout()

        unavailableStack.axis = .vertical
        unavailableStack.spacing = 10

        let titleLabel = UILabel()

        titleLabel.toAutoLayout()

        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.text = "Сервис недоступен"
        titleLabel.textAlignment = .center
        if #available(iOS 13.0, *) {
            titleLabel.textColor = .label
        } else {
            titleLabel.textColor = .black
        }

        unavailableStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()

        subtitleLabel.toAutoLayout()

        subtitleLabel.font = .systemFont(ofSize: 17)
        subtitleLabel.text = "Не получено системное разрешение"
        subtitleLabel.textAlignment = .center
        if #available(iOS 13.0, *) {
            subtitleLabel.textColor = .secondaryLabel
        } else {
            subtitleLabel.textColor = .systemGray
        }

        unavailableStack.addArrangedSubview(subtitleLabel)

        return unavailableStack
    }()

    private lazy var goToSettingsButton: UIButton = {
        let goToSettingsButton = UIButton(type: .system)

        goToSettingsButton.toAutoLayout()
        goToSettingsButton.setTitle("Перейти в настройки", for: .normal)
        goToSettingsButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        return goToSettingsButton
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    func makeButton(visible: Bool) {
        if visible {
            unavailableStack.addArrangedSubview(goToSettingsButton)
        } else {
            goToSettingsButton.removeFromSuperview()
        }
    }

    func setButtonAction(action: @escaping () -> Void) {
        buttonAction = action
    }

    // MARK: - Private methods

    private func setupView() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.toAutoLayout()
        addSubview(blurEffectView)

        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        addSubview(unavailableStack)
        NSLayoutConstraint.activate([
            unavailableStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            unavailableStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            unavailableStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc func buttonTapped(_ sender: UIButton) {
        buttonAction?()
    }
}
