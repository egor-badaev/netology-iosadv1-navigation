//
//  ViewController.swift
//  AVFoundation_Audio
//
//  Created by Niki Pavlove on 18.02.2021.
//

import UIKit

class PlayerViewController: UIViewController {
    
    // MARK: - Properties
    
    private lazy var playerManager: PlayerManager = {
        let manager = PlayerManager()
        manager.delegate = self
        return manager
    }()
    
    private lazy var playButton = AVControlButton(imageName: "play.fill", controller: self, selector: #selector(startPlaying))
    
    private lazy var stopButton = AVControlButton(imageName: "stop.fill", controller: self, selector: #selector(stopPlaying))
    
    private lazy var pauseButton: AVControlButton = {
        let pauseButton = AVControlButton(imageName: "pause.fill", controller: self, selector: #selector(pausePlaying))
        pauseButton.isHidden = true
        return pauseButton
    }()
    
    private lazy var previousButton = AVControlButton(imageName: "backward.end.fill", controller: self, selector: #selector(prevTrack))
    
    private lazy var nextButton = AVControlButton(imageName: "forward.end.fill", controller: self, selector: #selector(nextTrack))
    
    private lazy var avControlsView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 40.0
        stackView.addArrangedSubview(previousButton)
        stackView.addArrangedSubview(playButton)
        stackView.addArrangedSubview(pauseButton)
        stackView.addArrangedSubview(stopButton)
        stackView.addArrangedSubview(nextButton)
        return stackView
    }()
    
    private let trackLabel: UILabel = {
        let trackLabel = UILabel()
        trackLabel.translatesAutoresizingMaskIntoConstraints = false
        trackLabel.font = .systemFont(ofSize: 17.0, weight: .bold)
        trackLabel.textAlignment = .center
        if #available(iOS 13.0, *) {
            trackLabel.textColor = .label
        } else {
            trackLabel.textColor = .black
        }
        return trackLabel
    }()
    
    private let artistLabel: UILabel = {
        let artistLabel = UILabel()
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.font = .systemFont(ofSize: 14.0)
        artistLabel.textAlignment = .center
        if #available(iOS 13.0, *) {
            artistLabel.textColor = .secondaryLabel
        } else {
            artistLabel.textColor = .gray
        }
        return artistLabel
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        var ai: UIActivityIndicatorView

        if #available(iOS 13.0, *) {
            ai = UIActivityIndicatorView(style: .large)
        } else {
            ai = UIActivityIndicatorView(style: .gray)
        }

        ai.toAutoLayout()
        ai.hidesWhenStopped = true

        return ai
    }()
    
    //MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupUI()
        DispatchQueue.global().async { [weak self] in
            self?.playerManager.setup()
        }
    }
    
    //MARK: - Actions

    @objc private func startPlaying() {
        playerManager.startPlayback()
    }
    
    @objc private func stopPlaying() {
        playerManager.stopPlayback()
    }
    
    @objc private func pausePlaying() {
        playerManager.pausePlayback()
    }
    
    @objc private func prevTrack() {
        playerManager.switchTrack(.previous)
    }
    
    @objc private func nextTrack() {
        playerManager.switchTrack(.next)
    }
    
    // MARK: - Private methods
    
    private func setupUI() {
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        view.addSubview(activityIndicator)
        view.addSubview(avControlsView)
        view.addSubview(trackLabel)
        view.addSubview(artistLabel)
        
        let constraints = [
            avControlsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avControlsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 18.0),
            pauseButton.widthAnchor.constraint(equalToConstant: 18.0),
            stopButton.widthAnchor.constraint(equalToConstant: 18.0),
            trackLabel.topAnchor.constraint(equalTo: avControlsView.bottomAnchor, constant: 32.0),
            trackLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
            trackLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0),
            artistLabel.topAnchor.constraint(equalTo: trackLabel.bottomAnchor, constant: 4.0),
            artistLabel.leadingAnchor.constraint(equalTo: trackLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: trackLabel.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)

        avControlsView.isHidden = true
        artistLabel.isHidden = true
        trackLabel.isHidden = true
        activityIndicator.startAnimating()
    }
    
}

// MARK: - PlayerManagerDelegate
    
extension PlayerViewController: PlayerManagerDelegate {

    func playerDidLoad() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.avControlsView.isHidden = false
            self.artistLabel.isHidden = false
            self.trackLabel.isHidden = false
        }
    }

    func setTrack(_ track: AudioTrack) {
        DispatchQueue.main.async { [weak self] in
            self?.trackLabel.text = track.title
            self?.artistLabel.text = track.artist
        }
    }
    
    func togglePlayPause() {
        DispatchQueue.main.async { [weak self] in
            self?.playButton.isHidden.toggle()
            self?.pauseButton.isHidden.toggle()
        }
    }
}
