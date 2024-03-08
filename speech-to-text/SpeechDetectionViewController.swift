//
//  ViewController.swift
//  speech-to-text
//
//  Created by Mariano Martin Battaglia on 08/03/2024.
//

import UIKit
import Speech

class SpeechDetectionViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var detectedTextLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var startButton: UIButton!

    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.startButton.backgroundColor = UIColor.gray
        self.checkAndRequestMicrophonePermission()
        self.requestSpeechAuthorization()
    }


    @IBAction func startButtonTapped(_ sender: Any) {
        if isRecording {
            cancelRecording()
            isRecording = false
            startButton.backgroundColor = UIColor.gray
        } else {
            self.recordAndRecognizeSpeech()
            isRecording = true
            startButton.backgroundColor = UIColor.red
        }
    }
    
    func cancelRecording() {
        recognitionTask?.finish()
        recognitionTask = nil
        
        // stop audio
        request.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(title: "Speech Recognizer Error", message: "There has been an audio engine error.")
            print(error)
            return
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not supported for your current locale.")
            return
        }
        
        if !myRecognizer.isAvailable {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not currently available. Check back at a later time.")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.detectedTextLabel.text = bestString
                
                // Word recognition
                var lastString: String = ""
                
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = String(bestString[indexTo...])
//                    lastString = bestString.substring(from: indexTo)
                }
                
                self.checkForColorsSaid(resultString: lastString)
            } else if let error = error {
                print(error)
            }
        })
        
    }
    
    func checkForColorsSaid(resultString: String) {
        switch resultString {
            case "red":
                colorView.backgroundColor = UIColor.red
            case "orange":
                colorView.backgroundColor = UIColor.orange
            case "yellow":
                colorView.backgroundColor = UIColor.yellow
            case "green":
                colorView.backgroundColor = UIColor.green
            case "blue":
                colorView.backgroundColor = UIColor.blue
            case "purple":
                colorView.backgroundColor = UIColor.purple
            case "black":
                colorView.backgroundColor = UIColor.black
            case "white":
                colorView.backgroundColor = UIColor.white
            case "gray":
                colorView.backgroundColor = UIColor.gray
            default: break
        }
    }
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                    case .notDetermined:
                        self.startButton.isEnabled = false
                        self.detectedTextLabel.text = "Speech recognition not yet authorized"
                    case .denied:
                        self.startButton.isEnabled = false
                        self.detectedTextLabel.text = "User denied access to speech recognition"
                    case .restricted:
                        self.startButton.isEnabled = false
                        self.detectedTextLabel.text = "Speech recognition restricted on this device"
                    case .authorized:
                        self.startButton.isEnabled = true
                    @unknown default:
                        return
                }
            }
        }
    }
    
    func checkAndRequestMicrophonePermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        print("Status: \(status)")
        
        if status != .authorized {
            AVCaptureDevice.requestAccess(for: .audio) { userAction in
                print("Access: \(userAction)")
            }
        }
    }
    
    
    func sendAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}
