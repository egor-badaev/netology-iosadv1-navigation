//
//  ViewController.swift
//  WebView
//
//  Created by Niki Pavlove on 18.02.2021.
//

import UIKit
import WebKit

class VideoPlayerViewController: UIViewController {

    private var currentIndex = 0 {
        didSet {
            let oldIndexPath = IndexPath(row: oldValue, section: 0)
            let newIndexPath = IndexPath(row: currentIndex, section: 0)
            tableView.reloadRows(at: [oldIndexPath, newIndexPath], with: .none)
        }
    }
    
    private let reuseID = "cell"
    private var firstViewLoaded = false

    private let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: CGRect(origin: .zero, size: .zero), configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.contentMode = .scaleToFill
        webView.backgroundColor = UIColor(red: 0.36078431370000003, green: 0.38823529410000002, blue: 0.4039215686, alpha: 1.0)
        return webView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        view.addSubview(webView)
        view.addSubview(tableView)
        
        let constraints = [
            webView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.heightAnchor.constraint(equalTo: webView.widthAnchor, multiplier: 163 / 375),
            tableView.topAnchor.constraint(equalTo: webView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
    }


    func playFirstVideoIfNeeded() {
        guard !firstViewLoaded else {
            return
        }
        playVideo()
    }
    
    private func playVideo(index: Int = 0) {
        guard VideoPlaylistProvider.playlist.indices.contains(index) else {
            print("Invalid index")
            return
        }
        
        let urlString = VideoPlaylistProvider.playlist[index].url
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        currentIndex = index
        firstViewLoaded = true
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension VideoPlayerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        VideoPlaylistProvider.playlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        cell.textLabel?.text = VideoPlaylistProvider.playlist[indexPath.row].title
        cell.accessoryType = currentIndex == indexPath.row ? .checkmark : .none
        return cell
    }
}

extension VideoPlayerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playVideo(index: indexPath.row)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
