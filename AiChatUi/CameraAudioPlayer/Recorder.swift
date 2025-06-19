//
//  Recorder.swift
//  AiChatUi
//
//  Created by Measna on 12/6/25.
//

import AVFoundation

protocol RecorderDelegate: AnyObject {
    func recording(data: Data)
}

class Recorder: NSObject {

    weak var delegate: RecorderDelegate?

    private let audioQueue = DispatchQueue(label: "dev.measna.echo.cancelling.audio.manager.queue")
    private var isCapturing = false
    
    private let recordingFormat: AudioStreamBasicDescription
    var voiceProcessingUnit: AudioUnit?
    
    override init() {
       
        self.recordingFormat = AudioStreamBasicDescription(
            mSampleRate: 16_000.0,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 16,
            mReserved: 0
        )

        super.init()
    }

    func start() {
        checkPermissionsAndStartRunning()
    }
    
    private func checkPermissionsAndStartRunning() {
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else {
                print("Microphone permission denied.")
                return
            }
            
            self.audioQueue.async { [weak self] in
                guard let self = self else { return }
                print("Recorder: Starting...")

                self.setupRecordingUnit()
            }
        }
    }

    func stop() {
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            print("Recorder: Stopping...")
            self.isCapturing = false
            self.stopRecordingUnit()
            print("Recorder: Stopped.")
        }
    }
    
    func cleanUp() {
        stop()
    }
    
    // This method is called from the C-style callback.
    func processRecordedAudio(bufferList: UnsafeMutablePointer<AudioBufferList>, frameCount: UInt32) {
        
        guard isCapturing else { return }
        
        let audioBuffer = bufferList.pointee.mBuffers
        if let mData = audioBuffer.mData {
            let data = Data(bytes: mData, count: Int(audioBuffer.mDataByteSize))
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.recording(data: data)
            }
        }
    }
    
    private func setupRecordingUnit() {
        var audioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                                                    componentSubType: kAudioUnitSubType_VoiceProcessingIO,
                                                                    componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                    componentFlags: 0,
                                                                    componentFlagsMask: 0)
        
        guard let audioComponent = AudioComponentFindNext(nil, &audioComponentDescription) else {
            return
        }
        
        var audioUnit: AudioUnit?
        guard AudioComponentInstanceNew(audioComponent, &audioUnit) == noErr, let unit = audioUnit else {
            return
        }
        self.voiceProcessingUnit = unit
        
        // Enable microphone input.
        var enableInput: UInt32 = 1
        AudioUnitSetProperty(unit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableInput, UInt32(MemoryLayout<UInt32>.size))
        
        // IMPORTANT: Disable speaker output on this unit. Playback is handled by AVAudioEngine.
        var enableOutput: UInt32 = 0
        AudioUnitSetProperty(unit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &enableOutput, UInt32(MemoryLayout<UInt32>.size))
        
        // Enable echo cancellation.
        var bypassVoiceProcessing: UInt32 = 0
        AudioUnitSetProperty(unit, kAUVoiceIOProperty_BypassVoiceProcessing, kAudioUnitScope_Global, 0, &bypassVoiceProcessing, UInt32(MemoryLayout<UInt32>.size))
        
        // Set the format for the microphone input.
        var inputFormat = self.recordingFormat
        AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &inputFormat, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        
        // Set the input callback for recording.
        var inputCallbackStruct = AURenderCallbackStruct(inputProc: audioInputCallback, inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
        AudioUnitSetProperty(unit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &inputCallbackStruct, UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        
        // Initialize and start the unit.
        guard AudioUnitInitialize(unit) == noErr else { return }
        guard AudioOutputUnitStart(unit) == noErr else { return }
        
        self.isCapturing = true
        print("Recorder: Recording unit started with AEC.")
    }
    
    private func stopRecordingUnit() {
        if let audioUnit = voiceProcessingUnit {
            AudioOutputUnitStop(audioUnit)
            AudioUnitUninitialize(audioUnit)
            AudioComponentInstanceDispose(audioUnit)
            self.voiceProcessingUnit = nil
        }
    }
}

// MARK: - C-Style Audio Callback
private func audioInputCallback(inRefCon: UnsafeMutableRawPointer,
                                ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                                inTimeStamp: UnsafePointer<AudioTimeStamp>,
                                inBusNumber: UInt32,
                                inNumberFrames: UInt32,
                                ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    
    let recorder = Unmanaged<Recorder>.fromOpaque(inRefCon).takeUnretainedValue()
    
    var bufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: AudioBuffer(mNumberChannels: 1, mDataByteSize: inNumberFrames * 2, mData: malloc(Int(inNumberFrames * 2))))
    
    let status = AudioUnitRender(recorder.voiceProcessingUnit!, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList)
    
    if status == noErr {
        recorder.processRecordedAudio(bufferList: &bufferList, frameCount: inNumberFrames)
    }
    
    free(bufferList.mBuffers.mData)
    
    return status
}
