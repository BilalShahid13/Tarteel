//
//  LessonViewController.swift
//  AdaptiveQuran
//
//  Created by Bilal Shahid on 5/1/19.
//  Copyright © 2019 Bilal Shahid. All rights reserved.
//

import UIKit
import AVFoundation

class LessonViewController: UIViewController, AVAudioPlayerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //Outlets
    @IBOutlet weak var CollectionView: UICollectionView!
    @IBOutlet weak var countDownLabel: UILabel!
    @IBOutlet weak var countUpLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var delaySlider: UISlider!
    @IBOutlet weak var delayLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    
    //Variable Declerations
    var callback : ((Bool)->())?
    var verseByVerseSelectionCheck:Bool?
    var lessonIndex = -1
    var allocatedayahIds = [Int]()
    var allocatedPhraseIds = [Int]()
    var allocatedPhrases = [String]()
    var allocatedVersesIds = [Int]()
    var allocatedVerses = [String]()
    var surahId: Int = -1
    var userTag = -1
    var selectedUserRepetitions = [10,5,2]
    var dispatchQueueWorkItem: DispatchWorkItem?
    var delayInSeconds = 1
    var onTapWordPlayCheck = false
    var onTapWordHighlightCheck = false
    var previousSelected : IndexPath?
    var currentSelected : Int?
    var surahChunkNumber: Int = 1
    var audioBuffer: AVAudioPCMBuffer?
    var audioFormat: AVAudioFormat?
    var audioSampleRate: Float = 0
    var audioLengthSeconds: Float = 0
    var audioLengthSamples: AVAudioFramePosition = 0
    var needsFileScheduled = true
    let rateSliderValues: [Float] = [0.5, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
    var rateValue: Float = 1.0 {
        didSet {
            rateEffect.rate = rateValue
            updateRateLabel()
        }
    }
    var updater: CADisplayLink?
    var currentFrame: AVAudioFramePosition {
        guard let lastRenderTime = player.lastRenderTime,
            let playerTime = player.playerTime(forNodeTime: lastRenderTime) else {
                return 0
        }
        
        return playerTime.sampleTime
    }
    var seekFrame: AVAudioFramePosition = 0
    var currentPosition: AVAudioFramePosition = 0
    let pauseImageHeight: Float = 26.0
    let minDb: Float = -80.0
    
    enum TimeConstant {
        static let secsPerMin = 60
        static let secsPerHour = TimeConstant.secsPerMin * 60
    }
    
    //AVAudio Properties
    var engine = AVAudioEngine()
    var player = AVAudioPlayerNode()
    var rateEffect = AVAudioUnitTimePitch()
    
    var audioFile: AVAudioFile? {
        didSet {
            if let audioFile = audioFile {
                audioLengthSamples = audioFile.length
                audioFormat = audioFile.processingFormat
                audioSampleRate = Float(audioFormat?.sampleRate ?? 44100)
                audioLengthSeconds = Float(audioLengthSamples) / audioSampleRate
            }
        }
    }
    var audioFileURL: URL? {
        didSet {
            if let audioFileURL = audioFileURL {
                audioFile = try? AVAudioFile(forReading: audioFileURL)
            }
        }
    }
    
    //View Functions
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
         navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(settingButtonHandler))
        self.setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateRateLabel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent {
            player.stop()
            updater?.isPaused = true
            playPauseButton.isSelected = false
            disconnectVolumeTap()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //CollectionView Functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.verseByVerseSelectionCheck == false
        {
            return self.allocatedPhrases.count
        }
        else
        {
            return self.allocatedVersesIds.count
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SurahCell",
                                                      for: indexPath) as! LessonCollectionViewCell
        if currentSelected != nil && currentSelected == indexPath.row
        {
            cell.backgroundColor = #colorLiteral(red: 0.09896145016, green: 0.7481964827, blue: 0.5541328192, alpha: 1)
            surahChunkNumber = indexPath.row
            cell.text.textColor = .white
        }
        else
        {
            cell.backgroundColor = UIColor.white
            cell.text.textColor = .black
        }
        cell.layer.cornerRadius = 10
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.clear.cgColor
        cell.text.text = allocatedPhrases[indexPath.row]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if previousSelected != nil{
            if let cell = collectionView.cellForItem(at: previousSelected!) as? LessonCollectionViewCell{
                cell.backgroundColor = UIColor.white
                cell.text.textColor = .black
            }
        }
        player.stop()
        onTapWordPlayCheck = true
        updater?.isPaused = true
        playPauseButton.isSelected = false
        disconnectVolumeTap()
        
        surahChunkNumber = indexPath.row
        initialSetup()
        playPauseButton.sendActions(for: .touchUpInside)
        
        currentSelected = indexPath.row
        previousSelected = indexPath
        self.CollectionView.reloadItems(at: [indexPath])
    }
    
    func highlightCollectionViewCell(_ CollectionView: UICollectionView, index pSelected: Int)
    {
        if let cell = CollectionView.cellForItem(at: IndexPath(row: pSelected, section: 0)) as? LessonCollectionViewCell{
            cell.backgroundColor = UIColor.white
            cell.text.textColor = .black
        }
        print (surahChunkNumber)
        currentSelected = surahChunkNumber
        previousSelected = IndexPath(row: surahChunkNumber, section: 0)
        self.CollectionView.reloadItems(at: [IndexPath(row: currentSelected!, section: 0)])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if verseByVerseSelectionCheck == false {
            let text = NSAttributedString(string: allocatedPhrases[indexPath.row])
            return CGSize(width: abs((text.size().width*2)) + 5, height : 46)
        }
        else {
            let text = NSAttributedString(string: allocatedPhrases[indexPath.row])
            let width = (text.size().width*2)
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad){
                let multiplier = Int(width/720)
                if multiplier >= 1
                {
                    return CGSize(width: 320, height : CGFloat(46 + (multiplier * 46)))
                }
                else
                {
                    return CGSize(width: width, height : 46)
                }
            }
            else
            {
                let multiplier = Int(width/260)
                print("Multiplier", multiplier, width)
                if multiplier >= 1
                {
                    return CGSize(width: 320, height : CGFloat(46 + (multiplier * 46)))
                }
                else
                {
                    return CGSize(width: width, height : 46)
                }
            }
        }
    }
    
    //SoundPlaying Functions
    func setup()
    {
        self.title = DBManager.shared.getSurahName(at: surahId - 1)
        allocatedPhrases = DBManager.shared.getSelectedSurahPhrases(surahId: surahId, ayahs: allocatedayahIds)
        allocatedPhraseIds = DBManager.shared.getSelectedSurahPhrasesIds(surahId: surahId, ayahs: allocatedayahIds)
        allocatedVerses = DBManager.shared.getSelectedSurahVerses(surahId: surahId, ayahs: allocatedayahIds)
        allocatedVersesIds = DBManager.shared.getSelectedSurahVerseIds(surahId: surahId, ayahs: allocatedayahIds)
        
        if verseByVerseSelectionCheck == true{
            allocatedPhrases = allocatedVerses
            allocatedPhraseIds = allocatedVersesIds
        }
        
        self.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        currentSelected = 0
        previousSelected = (IndexPath(row: 0, section: 0))
        self.CollectionView.reloadItems(at: [IndexPath(row: currentSelected!, section: 0)])
        setupRateSlider()
        initialSetup()
    }
    
    @objc func settingButtonHandler()
    {
        let alert = UIAlertController(title: "Select Recitation Mode", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Phrase by Phrase", style: .default, handler: { action in
            if self.verseByVerseSelectionCheck == true
            {
                if self.playPauseButton.isSelected
                {
                    self.player.stop()
                    self.updater?.isPaused = true
                    self.playPauseButton.isSelected = false
                    self.disconnectVolumeTap()
                }
                self.verseByVerseSelectionCheck = false
                self.callback?(self.verseByVerseSelectionCheck!)
                self.CollectionView.collectionViewLayout.invalidateLayout()
                self.CollectionView.reloadData()
                self.progressBar.progress = 0
                self.setup()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Verse by Verse", style: .default, handler: { action in
            if self.verseByVerseSelectionCheck == false
            {
                if self.playPauseButton.isSelected
                {
                    self.player.stop()
                    self.updater?.isPaused = true
                    self.playPauseButton.isSelected = false
                    self.disconnectVolumeTap()
                }
                self.verseByVerseSelectionCheck = true
                self.callback?(self.verseByVerseSelectionCheck!)
                self.CollectionView.collectionViewLayout.invalidateLayout()
                self.CollectionView.reloadData()
                self.progressBar.progress = 0
                self.setup()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.modalPresentationStyle = .popover
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = self.navigationItem.rightBarButtonItem
        }
        
        present(alert, animated:true, completion: nil)
    }
    func initialSetup()
    {
        setupAudio()
        countUpLabel.text = formatted(time: 0)
        countDownLabel.text = formatted(time: audioLengthSeconds)
        
        updater = CADisplayLink(target: self, selector: #selector(updateUI))
        updater?.add(to: .current, forMode: .default)
        updater?.isPaused = true
    }
    
    @IBAction func didChangeRateValue(_ sender: UISlider) {
        let index = round(sender.value)
        speedSlider.setValue(Float(index), animated: false)
        rateValue = rateSliderValues[Int(index)]
    }
    @IBAction func didChangeDelayValue(_ sender: UISlider) {
        delayInSeconds = Int(round(sender.value))
        delayLabel.text = "Delay: " + String(delayInSeconds) + "x"
    }
    
    @IBAction func playTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if onTapWordHighlightCheck == true{
            onTapWordHighlightCheck = false
            self.highlightCollectionViewCell(self.CollectionView, index: self.surahChunkNumber - 1)
        }
        
        if currentPosition >= audioLengthSamples {
            updateUI()
        }
        if self.player.isPlaying {
            self.disconnectVolumeTap()
            self.updater?.isPaused = true
            self.player.pause()
        } else {
            self.updater?.isPaused = false
            self.connectVolumeTap()
            if self.needsFileScheduled {
                self.needsFileScheduled = false
                self.scheduleAudioFile()
            }
            self.player.play()
        }
    }
    
    @IBAction func forwardButton(_ sender: UIButton) {
        if (surahChunkNumber + 1) < allocatedPhrases.count{
            
            player.stop()
            updater?.isPaused = true
            playPauseButton.isSelected = false
            disconnectVolumeTap()
            
            self.surahChunkNumber += 1
            initialSetup()
            highlightCollectionViewCell(CollectionView, index: surahChunkNumber - 1)
            playPauseButton.sendActions(for: .touchUpInside)
        }
    }
    @IBAction func rewindButton(_ sender: UIButton) {
        if (surahChunkNumber - 1) >= 0{
            
            player.stop()
            updater?.isPaused = true
            playPauseButton.isSelected = false
            disconnectVolumeTap()
            
            self.surahChunkNumber -= 1
            initialSetup()
            highlightCollectionViewCell(CollectionView, index: surahChunkNumber + 1)
            playPauseButton.sendActions(for: .touchUpInside)
        }
    }
    
    @objc func updateUI() {
        currentPosition = currentFrame + seekFrame
        currentPosition = max(currentPosition, 0)
        currentPosition = min(currentPosition, audioLengthSamples)
        
        progressBar.progress = Float(currentPosition) / Float(audioLengthSamples)
        let time = Float(currentPosition) / audioSampleRate
        countUpLabel.text = formatted(time: time)
        countDownLabel.text = formatted(time: audioLengthSeconds - time)
        
        if currentPosition >= audioLengthSamples {
            print("Chunk Finished")
            let chunkTotalTime = time
            player.stop()
            updater?.isPaused = true
            playPauseButton.isSelected = false
            disconnectVolumeTap()
            if(self.surahChunkNumber < self.allocatedPhrases.count - 1)
            {
                self.surahChunkNumber += 1
                self.initialSetup()
                
                if onTapWordPlayCheck == false{
                    dispatchQueueWorkItem = DispatchWorkItem {
                        sleep(UInt32(Int(chunkTotalTime)*self.delayInSeconds))
                        DispatchQueue.main.async {
                            if !self.playPauseButton.isSelected
                            {
                                self.playPauseButton.sendActions(for: .touchUpInside)
                            }
                        }
                    }
                    DispatchQueue.global().async(execute: dispatchQueueWorkItem!)
                    self.highlightCollectionViewCell(self.CollectionView, index: self.surahChunkNumber - 1)
                }
                else
                {
                    onTapWordPlayCheck = false
                    onTapWordHighlightCheck = true
                }
                
            }
            else
            {
                self.surahChunkNumber = 0
                self.previousSelected = IndexPath(row: self.allocatedPhrases.count - 1, section: 0)
                self.highlightCollectionViewCell(self.CollectionView, index: self.previousSelected!.row)
                self.initialSetup()
            }
        }
    }
    
    func setupRateSlider() {
        let numSteps = rateSliderValues.count-1
        speedSlider.minimumValue = 0
        speedSlider.maximumValue = Float(numSteps)
        speedSlider.isContinuous = true
        speedSlider.setValue(1.0, animated: false)
        rateValue = 1.0
        updateRateLabel()
    }
    
    func updateRateLabel() {
        rateLabel.text = "Speed: \(rateValue)x"
        let trackRect = speedSlider.trackRect(forBounds: speedSlider.bounds)
        _ = speedSlider.thumbRect(forBounds: speedSlider.bounds , trackRect: trackRect, value: speedSlider.value)
    }
    
    func formatted(time: Float) -> String {
        guard !(time.isNaN || time.isInfinite) else {
            return "illegal value"
        }
        var secs = Int(ceil(time))
        var hours = 0
        var mins = 0
        
        if secs > TimeConstant.secsPerHour {
            hours = secs / TimeConstant.secsPerHour
            secs -= hours * TimeConstant.secsPerHour
        }
        
        if secs > TimeConstant.secsPerMin {
            mins = secs / TimeConstant.secsPerMin
            secs -= mins * TimeConstant.secsPerMin
        }
        
        var formattedString = ""
        if hours > 0 {
            formattedString = "\(String(format: "%02d", hours)):"
        }
        formattedString += "\(String(format: "%02d", mins)):\(String(format: "%02d", secs))"
        return formattedString
    }
    
    func setupAudio() {
        if verseByVerseSelectionCheck == false {
            let fileName = String(allocatedPhraseIds[surahChunkNumber])
            audioFileURL  = Bundle.main.url(forResource: fileName,withExtension: ".mp3")
        }
        else
        {
            let fileName = "V" + String(allocatedPhraseIds[surahChunkNumber])
            audioFileURL  = Bundle.main.url(forResource: fileName,withExtension: ".mp3")
        }
        engine.attach(player)
        engine.attach(rateEffect)
        engine.connect(player, to: rateEffect, format: audioFormat)
        engine.connect(rateEffect, to: engine.mainMixerNode, format: audioFormat)
        
        engine.prepare()
        
        do {
            try engine.start()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func scheduleAudioFile() {
        guard let audioFile = audioFile else { return }
        seekFrame = 0
        player.scheduleFile(audioFile, at: nil) { [weak self] in
            self?.needsFileScheduled = true
        }
    }
    
    func connectVolumeTap() {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, when in
            
            guard let channelData = buffer.floatChannelData
                else {
                    return
            }
            
            let channelDataValue = channelData.pointee
            let channelDataValueArray = stride(from: 0,
                                               to: Int(buffer.frameLength),
                                               by: buffer.stride).map{ channelDataValue[$0] }
            let channelDataValueArray1 = channelDataValueArray.map{ $0 * $0 }.reduce(0, +)
            let rms = sqrt(channelDataValueArray1 / Float(buffer.frameLength))
            _ = 20 * log10(rms)
        }
    }
    
    func scaledPower(power: Float) -> Float {
        guard power.isFinite else { return 0.0 }
        
        if power < minDb {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        } else {
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
    
    func disconnectVolumeTap() {
        engine.mainMixerNode.removeTap(onBus: 0)
        //volumeMeterHeight.constant = 0
    }
    
    func seek(to time: Float) {
        guard let audioFile = audioFile,
            let updater = updater else {
                return
        }
        
        seekFrame = currentPosition + AVAudioFramePosition(time * audioSampleRate)
        seekFrame = max(seekFrame, 0)
        seekFrame = min(seekFrame, audioLengthSamples)
        currentPosition = seekFrame
        
        player.stop()
        
        if currentPosition < audioLengthSamples {
            
            needsFileScheduled = false
            
            player.scheduleSegment(audioFile, startingFrame: seekFrame, frameCount: AVAudioFrameCount(audioLengthSamples - seekFrame), at: nil) { [weak self] in
                self?.needsFileScheduled = true
            }
            
            if !updater.isPaused {
                player.play()
            }
        }
    }
}
