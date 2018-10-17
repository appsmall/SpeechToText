//
//  ViewController.swift
//  SpeechToTextDemo
//
//  Created by Rahul Chopra on 04/09/18.
//  Copyright © 2018 Rahul Chopra. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    
    // speech recognizer knows what language the user is speaking in.
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    // This object handles the speech recognition requests. It provides an audio input to the speech recognizer.
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // The recognition task where it gives you the result of the recognition request. Having this object is handy as you can cancel or stop the task.
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // This is your audio engine. It is responsible for providing your audio input.
    private var audioEngine = AVAudioEngine()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isEnabled = false
        speechRecognizer?.delegate = self
        
        // we must request the authorization of Speech Recognition by calling this.
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
                case .authorized :
                    isButtonEnabled = true
                
                case .denied:
                    isButtonEnabled = false
                    print("User denied access to speech recognition")
                
                case .restricted:
                    isButtonEnabled = false
                    print("Speech recognition restricted on this device")
                
                case .notDetermined:
                    isButtonEnabled = false
                    print("Speech recognition not yet authorized")
            }
            self.microphoneButton.isEnabled = isButtonEnabled
        }
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // An audio session acts as an intermediary between your app and the operating system.
        // Create an AVAudioSession to prepare for the audio recording.
        let audioSession = AVAudioSession()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation)
        }
        catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        // Here we create the SFSpeechAudioBufferRecognitionRequest object.
        // Later, we use it to pass our audio data to Apple’s servers.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Check if the audioEngine (your device) has an audio input for recording.
        let inputNode = audioEngine.inputNode
        
        //  Check if the recognitionRequest object is instantiated and is not nil.
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        // Tell recognitionRequest to report partial results of speech recognition as the user speaks.
        recognitionRequest.shouldReportPartialResults = true
        
        // Start the recognition by calling the recognitionTask method of our speechRecognizer.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            // Define a boolean to determine if the recognition is final.
            var isFinal = false
            
            // If the result isn’t nil, set the textView.text property as our result‘s best transcription.
            // Then if the result is the final result, set isFinal to true.
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            // If there is no error or the result is final, stop the audioEngine (audio input)
            // and stop the recognitionRequest and recognitionTask. At the same time, we enable
            // the Start Recording button.
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        // Add an audio input to the recognitionRequest.
        // Note that it is ok to add the audio input after starting the recognitionTask.
        // The Speech Framework will start recognizing as soon as an audio input has been added.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        // Prepare and start the audioEngine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
    }
    
    // If speech recognition is unavailable or changes its status
    // Then, the microphoneButton.enable property should be set.
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        }
        else {
            microphoneButton.isEnabled = false
        }
    }

    @IBAction func microphoneBtnPressed(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
}

