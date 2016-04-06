//
//  BigVideoStoryBlockCell.swift
//  Homehapp
//
//  Created by Matti Dahlbom on 20/12/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
}

/**
 Displays a single video player.
*/
class BigVideoStoryBlockCell: BaseStoryBlockCell {
    private let playPauseImageViewInitialAlpha: CGFloat = 0.85
    
    @IBOutlet weak var snapshotImageView: CachedImageView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var playPauseImageView: UIImageView!
    @IBOutlet private weak var videoView: PlayerView!
    @IBOutlet private weak var addVideoButton: UIButton!
    @IBOutlet private weak var volumeButton: UIButton!
    @IBOutlet private weak var fullScreenButton: UIButton!
    
    /// Progress indicator for video upload
    @IBOutlet private weak var uploadProgressView: UIProgressView!
    
    /// Video URL the player was constructed with.
    var videoURL: NSURL?

    //private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    let videoViewMargin: CGFloat = 3
    
    var playFullscreenCallback: (Void -> Void)?
    
    var playButtonPressedTime: NSDate? = nil
    
    // Flag defining if the play was paused by the user
    private var pausedByUser = false
    private let kRotationAnimationKey = "com.homehapp.loadingAnimationKey"
    
    override var storyBlock: StoryBlock? {
        didSet {
            guard let video = storyBlock?.video else {
                log.error("Missing storyBlock.video!")
                return
            }
            videoURL = NSURL(string: video.scaledVideoUrl)
            snapshotImageView.imageUrl = video.scaledThumbnailUrl
            snapshotImageView.thumbnailData = video.thumbnailData
            snapshotImageView.imageFadeInDuration = 0.4
            snapshotImageView.fadeInColor = UIColor.whiteColor()
            playPauseImageView.alpha = playPauseImageViewInitialAlpha
            fullScreenButton.alpha = 0.0
            videoView.hidden = true
            volumeButton.alpha = 0.0
            
            if video.uploadProgress < 1.0 {
                uploadProgressView.progress = video.uploadProgress
                updateProgressBar()
            }
        }
    }
    
    override func setEditMode(editMode: Bool, animated: Bool) {
        super.setEditMode(editMode, animated: animated)
        
        // Sets hidden attributes of the controls according to state
        func setControlVisibility(allVisible allVisible: Bool = false) {
            addVideoButton.hidden = !editMode
            fullScreenButton.hidden = editMode
        }
        
        // Sets alpha attributes of the controls according to state
        func setControlAlphas() {
            addVideoButton.alpha = editMode ? 1.0 : 0.0
            fullScreenButton.alpha = editMode ? 0.0 : 1.0
        }
        
        if !animated {
            setControlVisibility()
            setControlAlphas()
        } else {
            setControlVisibility(allVisible: true)
            
            UIView.animateWithDuration(toggleEditModeAnimationDuration, animations: {
                setControlAlphas()
                self.layoutIfNeeded()
                }, completion: { finished in
                    setControlVisibility()
            })
        }
    }
    
    // MARK: Public methods

    func playEnded(notification: NSNotification) {
        guard let player = videoView?.player else {
            log.error("No player set!");
            return
        }
        
        log.debug("Video play ended.")
        pausedByUser = true
        player.pause()
        player.seekToTime(kCMTimeZero)
        
        UIView.animateWithDuration(0.4, animations: {
            self.videoView.alpha = 0.0
            self.volumeButton.alpha = 0.0
            self.playPauseImageView.alpha = self.playPauseImageViewInitialAlpha
            }) { finished in
                self.videoView.hidden = true
        }
    }
    
    func playPauseButtonPressed() {        
        if player == nil {
            if let url = videoURL {
                log.debug("Creating an AVPlayer with url: \(url)")
                
                playerItem = AVPlayerItem(URL: url)
                player = AVPlayer(playerItem: playerItem!)
                player!.actionAtItemEnd = .None
                player?.volume = 0.0
                videoView.player = player
                videoView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options:NSKeyValueObservingOptions(), context: nil)
                
                playButtonPressedTime = NSDate()
            }
        }
                
        guard let player = videoView?.player else {
            log.debug("No player set, cannot play");
            return
        }
        
        if player.rate > 0.0 {
            pauseVideo()
            pausedByUser = true
        } else {
            pausedByUser = false
            playVideo()
        }
    }
    
    func clearPlayer() {
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp", context: nil)
        pauseVideo()
        player = nil
        self.playPauseImageView.image = UIImage(named: "icon_play")
        playerItem = nil
    }
    
    func pauseVideo() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        player?.pause()
            
        UIView.animateWithDuration(0.4) {
            self.playPauseImageView.alpha = self.playPauseImageViewInitialAlpha
        }
    }
    
    func showLoading() {
        playPauseImageView.image = UIImage(named: "icon_loading")
        if playPauseImageView.layer.animationForKey(kRotationAnimationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = Float(M_PI * 2.0)
            rotationAnimation.duration = 2.0
            rotationAnimation.repeatCount = Float.infinity
            playPauseImageView.layer.addAnimation(rotationAnimation, forKey: kRotationAnimationKey)
        }
    }
    
    func hideLoading() {
        if playPauseImageView.layer.animationForKey(kRotationAnimationKey) != nil {
            UIView.animateWithDuration(0.4, animations: {
                self.playPauseImageView.alpha = 0.0
                }, completion: {
                    (value: Bool) in
                    self.playPauseImageView.layer.removeAnimationForKey(self.kRotationAnimationKey)
            })
        }
    }
    
    // MARK: Private methods
    
    private func playVideo() {
        if player?.rate == 0.0 && (playerItem?.playbackLikelyToKeepUp == true || playerItem?.playbackBufferFull == true) {
            log.debug("Playing video, playback likely to keep up");
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BigVideoStoryBlockCell.playEnded(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
            
            if videoView.hidden {
                videoView.alpha = 0.0
                videoView.hidden = false
                
                UIView.animateWithDuration(0.4) {
                    self.videoView.alpha = 1.0
                }
            }
            
            hideLoading()
            
            UIView.animateWithDuration(0.4, animations: {
                self.playPauseImageView.alpha = 0.0
                self.volumeButton.alpha = 1.0
                self.fullScreenButton.alpha = 1.0
                }, completion: {
                    (value: Bool) in
                    self.playPauseImageView.image = UIImage(named: "icon_play")
            })
            
            player?.play()
            
            // Send analytics event measuring how long the video buffering took
            if let playButtonPressedTime = playButtonPressedTime {
                let tracker = GAI.sharedInstance().defaultTracker
                let analyticsEventDictionary = GAIDictionaryBuilder.createTimingWithCategory("video", interval: NSDate().timeIntervalSinceDate(playButtonPressedTime), name: "video upload time", label: nil).build() as [NSObject : AnyObject]
                tracker.send(analyticsEventDictionary)
            }
            
        } else {
           showLoading()
        }
    }
    
    private func updateProgressBar() {
        if let video = storyBlock?.video where video.uploadProgress < 1.0 {
            uploadProgressView.hidden = false
            uploadProgressView.progress = video.uploadProgress
            runOnMainThreadAfter(delay: 0.3, task: {
                self.updateProgressBar()
            })
        } else {
          uploadProgressView.hidden = true
        }
    }
    
    // MARK: Key Value Observing
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "playbackLikelyToKeepUp" {
            if player!.rate <= 0 && !pausedByUser {
                playVideo()
            }
        }
    }

    // MARK: IBAction handlers
    
    @IBAction func playFullscreenButtonPressed(button: UIButton) {
        playFullscreenCallback?()
    }
    
    @IBAction func addVideoButtonPressed(button: UIButton) {
        addImagesCallback?(1)
    }
    
    @IBAction func volumeButtonPressed(button: UIButton) {
        if player?.volume == 0.0 {
            player?.volume = 1.0
            volumeButton.setImage(UIImage(named: "icon_sound_on"), forState: .Normal)
        } else {
            player?.volume = 0.0
            volumeButton.setImage(UIImage(named: "icon_muted"), forState: .Normal)
        }
    }
    
    // MARK: Lifecycle etc.
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapHandler = UITapGestureRecognizer(target: self, action: #selector(BigVideoStoryBlockCell.playPauseButtonPressed))
        addGestureRecognizer(tapHandler)
    }
}
