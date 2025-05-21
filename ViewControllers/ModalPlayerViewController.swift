//
//  ModalPlayerViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 8/2/20.
//  Copyright © 2020 Carquinez. All rights reserved.
//

import UIKit
import MediaPlayer

class ModalPlayerViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - UI Components (programmatic)
    private let creatorLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 20, weight: .bold)
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let songLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let venueLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let dateLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let timerSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let currentTimeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.text = "0:00"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let totalTimeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.text = "0:00"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let playButton: UIButton = {
        let btn = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            btn.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        } else {
            btn.setTitle("Play", for: .normal)
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.tintColor = .label
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        return btn
    }()
    
    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            btn.setBackgroundImage(UIImage(systemName: "backward.fill"), for: .normal)
        } else {
            btn.setTitle("<<", for: .normal)
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.tintColor = .label
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        return btn
    }()
    
    private let forwardButton: UIButton = {
        let btn = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            btn.setBackgroundImage(UIImage(systemName: "forward.fill"), for: .normal)
        } else {
            btn.setTitle(">>", for: .normal)
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.tintColor = .label
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        return btn
    }()

    private let shareButton: UIButton = {
        let btn = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            btn.setBackgroundImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        } else {
            btn.setTitle("Share", for: .normal)
        }
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.tintColor = .label
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        return btn
    }()

    private let modalPlayerTableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.tableFooterView = UIView()
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        return tv
    }()

    // MARK: - Other Properties
    private let notificationCenter: NotificationCenter = .default
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var isObservingPlayer = false  // Add flag to track observer state

    // MARK: - Life-cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()

        modalPlayerTableView.delegate = self
        modalPlayerTableView.dataSource = self
        modalPlayerTableView.register(ModalPlayerTableViewCell.self, forCellReuseIdentifier: "ModalPlayerCell")

        notificationCenter.addObserver(self, selector: #selector(playbackDidStart), name: .playbackStarted, object: nil)
        notificationCenter.addObserver(self, selector: #selector(playbackDidPause), name: .playbackPaused, object: self.player.playerQueue)
        notificationCenter.addObserver(self, selector: #selector(playbackDidRewind), name: .playbackRewind, object: self.player.playerQueue)

        initialDefaults()
        setupShow()
    }

    deinit {
        notificationCenter.removeObserver(self)
        if isObservingPlayer, let queue = player.playerQueue {
            queue.removeObserver(self, forKeyPath: "currentItem.status")
            isObservingPlayer = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notificationCenter.removeObserver(self)
        if isObservingPlayer, let queue = player.playerQueue {
            queue.removeObserver(self, forKeyPath: "currentItem.status")
            isObservingPlayer = false
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Labels Stack
        let labelsStack = UIStackView(arrangedSubviews: [creatorLabel, songLabel, venueLabel, dateLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2
        labelsStack.translatesAutoresizingMaskIntoConstraints = false

        // Slider row
        let sliderRow = UIStackView(arrangedSubviews: [currentTimeLabel, timerSlider, totalTimeLabel])
        sliderRow.axis = .horizontal
        sliderRow.spacing = 8
        sliderRow.alignment = .center
        sliderRow.translatesAutoresizingMaskIntoConstraints = false

        // Controls row
        let controlsRow = UIStackView(arrangedSubviews: [backButton, playButton, forwardButton, shareButton])
        controlsRow.axis = .horizontal
        controlsRow.spacing = 24
        controlsRow.alignment = .center
        controlsRow.distribution = .equalCentering
        controlsRow.translatesAutoresizingMaskIntoConstraints = false

        // Player controls container
        let playerControlsStack = UIStackView(arrangedSubviews: [labelsStack, sliderRow, controlsRow])
        playerControlsStack.axis = .vertical
        playerControlsStack.spacing = 12
        playerControlsStack.translatesAutoresizingMaskIntoConstraints = false

        // Container view for border
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.separator.cgColor
        containerView.layer.cornerRadius = 12
        containerView.backgroundColor = .secondarySystemBackground

        view.addSubview(modalPlayerTableView)
        view.addSubview(containerView)
        containerView.addSubview(playerControlsStack)

        NSLayoutConstraint.activate([
            // Table view at top
            modalPlayerTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            modalPlayerTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalPlayerTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            modalPlayerTableView.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: -12),

            // Container view at bottom
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            // Player controls inside container
            playerControlsStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            playerControlsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            playerControlsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            playerControlsStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

            // Play button size
            playButton.widthAnchor.constraint(equalToConstant: 60),
            playButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Other control buttons size
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            forwardButton.widthAnchor.constraint(equalToConstant: 40),
            forwardButton.heightAnchor.constraint(equalToConstant: 40),
            shareButton.widthAnchor.constraint(equalToConstant: 40),
            shareButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupActions() {
        playButton.addTarget(self, action: #selector(handlePlayButton), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(handleForwardButton), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(handleShareButton(_:)), for: .touchUpInside)
        timerSlider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
    }

    // MARK: - Actions
    @objc private func handleShareButton(_ sender: Any) {
        let url = utils.urlFromIdentifier(identifier: self.player.showMetadataModel?.metadata?.identifier)
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = (sender as? UIView) ?? self.view
        present(activityViewController, animated: true, completion: nil)
    }

    @objc private func handlePlayButton() { playPause() }
    @objc private func handleForwardButton() { player.playerQueue?.advanceToNextItem() }
    @objc private func handleBackButton() { player.rewindToPreviousItem() }

    // MARK: - Slider Handling
    @objc private func handleSliderChange() {
        player.timerSliderHandler(timerValue: timerSlider.value)
    }

    // MARK: - Existing Methods (unchanged below)
    func rewindFunctionality() {
        initialDefaults()
        setupShow()
        print("Rewind functionality")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if keyPath == #keyPath(AVQueuePlayer.currentItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            // Switch over status value
            switch status {
            case .readyToPlay:
                setupSong()
                print("ready to play")
            case .failed:
                print("failed ")
            case .unknown:
                print("unknown status")
            default:
                print("nope")
            }
            
        }

    }

    func setupSlider() {
        timerSlider.value = 0.0
        timerSlider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
    }

    func initialDefaults() {
        dateLabel.text = ""
        songLabel.text = ""
        venueLabel.text = ""
      }

    func setupShow() {
        guard let queue = player.playerQueue else { return }
        playPauseButtonImageSetup()
        if !isObservingPlayer {
            queue.addObserver(self, forKeyPath: "currentItem.status", options: .new, context: nil)
            isObservingPlayer = true
        }
        self.player.setupTimer()  { (seconds: Double?) -> Void in
             self.timerCallback(seconds: seconds)
        }
        setupSlider()
        setupSong()
        print("Setup Show")
    }
        
    func setupSong() {
        setupSongDetails()
        selectCurrentTrack()
    }
    
    func setupSongDetails() {
        player.songDetailsModel.songDetailsFromMetadata(row: player.getCurrentTrackIndex(), showModel: player.showMetadataModel)
        creatorLabel.text = player.showMetadataModel?.metadata?.creator?.stringValue
        songLabel.text = player.songDetailsModel.name
        dateLabel.text = player.songDetailsModel.date
        venueLabel.text = player.songDetailsModel.venue
    }    
   
    func selectCurrentTrack() {
        let index = player.getCurrentTrackIndex()
        let indexPath = IndexPath(item: index, section: 0)
        self.modalPlayerTableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
    }
    
    func timerCallback(seconds: Double?) {
        self.currentTimeLabel.text = utils.getTimerString(seconds: seconds)
        self.totalTimeLabel.text = self.player.getCurrentTrackTotalTimeString()
        if let duration = self.player.playerQueue?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            self.timerSlider.value = Float((seconds ?? 0.0)/(totalSeconds ))
        }
    }
    
    func playPauseButtonImageSetup() {
        guard let q = player.playerQueue else { return }
        if q.rate > 0.0 {
            if #available(iOS 13.0, *) {
                playButton.setBackgroundImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
            }
        }
        else {
            if #available(iOS 13.0, *) {
                playButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            }
        }
    }
    
    func playPause() {
        guard let q = player.playerQueue else { return }
        if q.rate > 0.0 {
            player.pause()
        }
        else {
            player.play()
        }
    }
    
    func reloadShow() {
        // This operation should probably belong to the player class
        if let mp3s = self.player.showMetadataModel?.mp3Array {
            player.loadQueuePlayer(tracks: mp3s)
        }
        setupShow()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let c = player.showMetadataModel?.mp3Array?.count {
            return c
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = modalPlayerTableView.dequeueReusableCell(withIdentifier: "ModalPlayerCell", for: indexPath) as? ModalPlayerTableViewCell,
            let mp3s = player.showMetadataModel?.mp3Array
            else {
                print("no songs")
                return UITableViewCell() }
        
        if let title = mp3s[indexPath.row].title, let track = mp3s[indexPath.row].track {
            cell.textLabel?.text = track + " " + title
        }
        else {
            if let name = mp3s[indexPath.row].name {
                cell.textLabel?.text = name
            }
            else {
                cell.textLabel?.text = "no song"
            }
                
        }

        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let indexPath = modalPlayerTableView.indexPathForSelectedRow else { return }
        let songIndex = indexPath.row
        print(songIndex)
        if let mp3Array = player.showMetadataModel?.mp3Array, songIndex >= 0 && songIndex < mp3Array.count {
            if let trackURL = self.player.trackURLfromName(name: player.showMetadataModel?.mp3Array?[songIndex].name) {
                do {
                    let _ = try trackURL.checkResourceIsReachable()
                    player.pause()
                    reloadShow()
                    for _ in 0..<songIndex {
                        player.playerQueue?.advanceToNextItem()
                    }
                    player.play()
                }
                catch {
                    print("Track not available")
                }
            }
        }
    }
    

}

private extension ModalPlayerViewController {
    @objc private func playbackDidStart(_ notification: Notification) {
        if #available(iOS 13.0, *) {
            playButton.setBackgroundImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        }
        print("Item playing -- modal player")
    }
    
    @objc private func playbackDidPause(_ notification: Notification) {
        if #available(iOS 13.0, *) {
            playButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        }
        print("Item paused -- modal player ")
    }
    
    @objc private func playbackDidRewind(_ notification: Notification) {
        if #available(iOS 13.0, *) {
            self.rewindFunctionality()
            print("Rewind ")
        }
    }

}
