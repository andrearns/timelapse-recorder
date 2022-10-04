import UIKit
import AVFoundation
import Photos

final class VideoRecordViewController: UIViewController {

    private let videoSaveService = VideoSaveService()
    
    var timer: Timer?
    var videoTime: Int = 0
    var isRecording: Bool = false
    var videoFrameDuration: CMTime = CMTimeMake(value: 0, timescale: 0)
    var nextPTS: CMTime = CMTimeMake(value: 0, timescale: 0)
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var stillImageOutput: AVCapturePhotoOutput?
    var outputURL: URL?
    
    private lazy var videoRecordView: VideoRecordView = {
        let view = VideoRecordView(startOrStop: startOrStop)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addViews()
        addConstraints()
        setupAVCapture(frameDuration: 0.1)
    }
    
    private func addViews() {
        view.addSubview(videoRecordView)
    }
    
    private func addConstraints() {
        NSLayoutConstraint.activate([
            videoRecordView.topAnchor.constraint(equalTo: view.topAnchor),
            videoRecordView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoRecordView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoRecordView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupAVCapture(frameDuration: Double) {
        videoFrameDuration = CMTimeMakeWithSeconds(frameDuration, preferredTimescale: 90000)
        
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        let input: AVCaptureDeviceInput!
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        do {
            input = try AVCaptureDeviceInput(device: frontCamera)
        } catch _ {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        stillImageOutput = AVCapturePhotoOutput()
        
        if session.canAddOutput(stillImageOutput!) {
            session.addOutput(stillImageOutput!)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = self.view.bounds
        videoRecordView.previewView.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    private final func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        degrees * .pi / 180
    }
    
    private func setupAssetWriterForURL(_ fileURL: URL, formatDescription: CMFormatDescription) -> Bool {
        do {
            assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mov)
        } catch {
            assetWriter = nil
            return false
        }
        
        assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
        assetWriterInput!.expectsMediaDataInRealTime = true
        
        if assetWriter!.canAdd(assetWriterInput!) {
            assetWriter!.add(assetWriterInput!)
        }
        
        // specify the prefered transform for the output file
        var rotationDegrees: CGFloat
        
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            rotationDegrees = -90.0
        case .landscapeLeft: // no rotation
            rotationDegrees = 0.0
        case .landscapeRight:
            rotationDegrees = 180.0
        case .portrait:
            fallthrough
        case .unknown:
            fallthrough
        case .faceUp:
            fallthrough
        case .faceDown:
            fallthrough
        default:
            rotationDegrees = 90.0
        }
        
        let rotationRadians = degreesToRadians(rotationDegrees)
        assetWriterInput!.transform = CGAffineTransform(rotationAngle: rotationRadians)
        
        nextPTS = .zero
        assetWriter!.startWriting()
        assetWriter!.startSession(atSourceTime: nextPTS)
        
        return true
    }
    
    @objc
    private func takePicture() {
        let settings = AVCapturePhotoSettings()
        stillImageOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    private func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(takePicture), userInfo: nil, repeats: true)
    }
    
    private func endTimer() {
        self.timer?.invalidate()
        let videoSpeed = Float(videoTime) * Float(0.1) / Float(15)
        videoTime = 0
    }
    
    private func saveVideoToCameraRoll(url: URL) {
        videoSaveService.saveVideo(with: url, completionHandler: {
            print("Video saved with success!")
        })
    }
    
    private func startOrStop(handleStart: () -> (), handleFinish: () -> ()) {
        if isRecording {
            if assetWriter != nil {
                assetWriterInput!.markAsFinished()
                assetWriter!.finishWriting {
                    self.assetWriterInput = nil
                    self.saveVideoToCameraRoll(url: self.outputURL!)
                    self.assetWriter = nil
                }
            }
            handleFinish()
            endTimer()
        } else {
            handleStart()
            startTimer()
        }
        
        isRecording = !isRecording
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}

extension VideoRecordViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}

extension VideoRecordViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if self.assetWriter == nil {
            self.outputURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())/\(mach_absolute_time()).mov")
            
            if self.assetWriterInput?.isReadyForMoreMediaData ?? false {
                self.nextPTS = CMTimeAdd(self.videoFrameDuration, self.nextPTS)
            }
        }
        videoTime += 1
    }
}
