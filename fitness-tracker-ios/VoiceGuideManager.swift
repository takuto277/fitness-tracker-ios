import Foundation
import AVFoundation
import UIKit

class VoiceGuideManager: NSObject, ObservableObject {
    static let shared = VoiceGuideManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isEnabled = true
    private var voice: AVSpeechSynthesisVoice?
    
    @Published var isSpeaking = false
    @Published var currentExercise = ""
    @Published var currentSet = 1
    @Published var totalSets = 5
    @Published var restTimeRemaining = 0
    @Published var isResting = false
    
    private override init() {
        super.init()
        setupVoice()
    }
    
    private func setupVoice() {
        // 日本語の音声を設定
        voice = AVSpeechSynthesisVoice(language: "ja-JP")
        
        // 音声設定
        let utterance = AVSpeechUtterance(string: "")
        utterance.voice = voice
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        synthesizer.delegate = self
    }
    
    // MARK: - Exercise Announcements
    
    func announceExercise(_ exercise: String) {
        guard isEnabled else { return }
        
        currentExercise = exercise
        let message = "\(exercise)を開始します"
        speak(message)
    }
    
    func announceSetStart(setNumber: Int, totalSets: Int) {
        guard isEnabled else { return }
        
        currentSet = setNumber
        self.totalSets = totalSets
        let message = "\(setNumber)セット目、\(totalSets)セット中です"
        speak(message)
    }
    
    func announceSetComplete(setNumber: Int, reps: Int, weight: Double) {
        guard isEnabled else { return }
        
        let message = "\(setNumber)セット目完了。\(reps)回、\(Int(weight))キログラムでした。休憩を開始します。"
        speak(message)
    }
    
    func announceWorkoutComplete() {
        guard isEnabled else { return }
        
        let message = "ワークアウト完了です。お疲れさまでした。"
        speak(message)
    }
    
    // MARK: - Countdown Functions
    
    func startCountdown(from count: Int, exercise: String) {
        guard isEnabled else { return }
        
        currentExercise = exercise
        let message = "\(exercise)の準備をしてください。\(count)秒後に開始します。"
        speak(message)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.countdown(from: count)
        }
    }
    
    private func countdown(from count: Int) {
        guard isEnabled else { return }
        
        if count > 0 {
            let message = "\(count)"
            speak(message)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.countdown(from: count - 1)
            }
        } else {
            let message = "開始！"
            speak(message)
        }
    }
    
    func startRepCountdown(from reps: Int) {
        guard isEnabled else { return }
        
        repCountdown(from: reps)
    }
    
    private func repCountdown(from reps: Int) {
        guard isEnabled else { return }
        
        if reps > 0 {
            let message = "\(reps)"
            speak(message)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.repCountdown(from: reps - 1)
            }
        } else {
            let message = "セット完了！"
            speak(message)
        }
    }
    
    // MARK: - Rest Timer Functions
    
    func startRestTimer(seconds: Int) {
        guard isEnabled else { return }
        
        isResting = true
        restTimeRemaining = seconds
        
        let message = "休憩時間\(seconds)秒を開始します"
        speak(message)
        
        restCountdown(from: seconds)
    }
    
    private func restCountdown(from seconds: Int) {
        guard isEnabled && isResting else { return }
        
        restTimeRemaining = seconds
        
        if seconds > 0 {
            // 10秒、5秒、3秒、2秒、1秒で音声アナウンス
            if seconds == 10 || seconds == 5 || seconds <= 3 {
                let message = "残り\(seconds)秒"
                speak(message)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.restCountdown(from: seconds - 1)
            }
        } else {
            let message = "休憩終了。次のセットを開始してください。"
            speak(message)
            isResting = false
        }
    }
    
    func stopRestTimer() {
        isResting = false
        restTimeRemaining = 0
    }
    
    // MARK: - Exercise Specific Functions
    
    func announceDumbbellPress(setNumber: Int, reps: Int, weight: Double) {
        guard isEnabled else { return }
        
        let message = "ダンベルプレス、\(setNumber)セット目。\(reps)回、\(Int(weight))キログラムで準備してください。"
        speak(message)
    }
    
    func announceAbsExercise(setNumber: Int, reps: Int) {
        guard isEnabled else { return }
        
        let message = "腹筋、\(setNumber)セット目。\(reps)回で準備してください。"
        speak(message)
    }
    
    func announceShoulderExercise(setNumber: Int, reps: Int, weight: Double) {
        guard isEnabled else { return }
        
        let message = "ショルダープレス、\(setNumber)セット目。\(reps)回、\(Int(weight))キログラムで準備してください。"
        speak(message)
    }
    
    // MARK: - Utility Functions
    
    private func speak(_ text: String) {
        guard isEnabled && !synthesizer.isSpeaking else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    func toggleVoiceGuide() {
        isEnabled.toggle()
        if !isEnabled {
            stopSpeaking()
        }
    }
    
    func setVoiceEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopSpeaking()
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceGuideManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
} 