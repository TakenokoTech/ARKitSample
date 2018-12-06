//
//  VedeoViewModel.swift
//  ARKitSample
//
//  Created by 竹仲 孝盛 on 2018/12/06.
//  Copyright © 2018年 たけのこ. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary
import Vision
import Photos


/// 
protocol VideoViewModelProtocol {
    var isRecoding: Bool { get set }
    func initCapture() -> AVCaptureVideoPreviewLayer?
    func startCapture()
    func stopCapture()
    func outputCapture(url: URL, callback: @escaping (Bool) -> Void)
}

class VideoViewModel: VideoViewModelProtocol {

    var isRecoding = false
    private let captureSession: AVCaptureSession = AVCaptureSession()
    private let fileOutput = AVCaptureMovieFileOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private weak var delegate: (AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureFileOutputRecordingDelegate)?
    
    /// Description
    ///
    /// - Parameter delegate: delegate description
    init(delegate: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureFileOutputRecordingDelegate) {
        self.delegate = delegate
    }
    
    /// ビデオ初期化
    public func initCapture() -> AVCaptureVideoPreviewLayer? {
        
        // captureSession.beginConfiguration()
        
        // 画素数
        // guard
        // captureSession.canSetSessionPreset(.high)
        // else {
        // assertionFailure("Error: failed video.")
        // return
        // }
        // captureSession.sessionPreset = .high
        // captureSession.commitConfiguration()
        
        // カメラ情報取得(30fps)
        guard
            let videoDevice = AVCaptureDevice.default(for: .video)
            else {
                assertionFailure("Error: failed video.")
                return nil
        }
        // videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
        // 入力の指定
        guard
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoInput)
            else {
                assertionFailure("Error: add AVCaptureDeviceInput.")
                return nil
        }
        captureSession.addInput(videoInput)
        // 出力の指定
        videoOutput.setSampleBufferDelegate(self.delegate, queue: DispatchQueue(label: "VideoQueue"))
        guard
            captureSession.canAddOutput(videoOutput),
            captureSession.canAddOutput(fileOutput)
            else {
                assertionFailure("Error: add AVCaptureVideoDataOutput.")
                return nil
        }
        captureSession.addOutput(videoOutput)
        captureSession.addOutput(fileOutput)
        // プレビューの指定
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.captureSession.startRunning()
        
        return previewLayer
    }
    
    /// ビデオ開始
    public func startCapture() {
        self.isRecoding = !self.isRecoding
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath: String? = "\(documentsDirectory)/temp.mp4"
        let fileURL: NSURL = NSURL(fileURLWithPath: filePath!)
        self.fileOutput.startRecording(to: fileURL as URL, recordingDelegate: delegate!)
    }

    /// ビデオ終了
    public func stopCapture() {
        self.isRecoding = !self.isRecoding
        self.captureSession.stopRunning()
        self.fileOutput.stopRecording()
    }
    
    /// ビデオ書き出し
    public func outputCapture(url: URL, callback: @escaping (Bool) -> Void) {
        // ライブラリへの保存
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }, completionHandler: { completed, error in
            if error != nil {
                ARLog.debug("\(error.debugDescription)")
            }
            if completed {
                print("Video is saved!")
            }
            callback(completed)
        })
    }
    
    /// イメージを水平方向に
    ///
    /// - Parameter image: image
    func correctAngleWithImage(image: UIImage) {
        do {
            let request = VNDetectHorizonRequest { (request: VNRequest, err: Error?) in
                if err != nil {
                    ARLog.debug(err)
                } else {
                    let horizonObservation: VNHorizonObservation? = request.results?.first as? VNHorizonObservation
                    ARLog.debug(horizonObservation)
                    let angle: CGFloat = horizonObservation?.angle ?? 0
                    let transform: String = NSCoder.string(for: horizonObservation!.transform)
                    ARLog.debug("\(angle) \(transform)")
                    // self.imageView!.transform = CGAffineTransform(rotationAngle: -horizonObservation!.angle)
                    // self.imageView.transform = CGAffineTransformInvert(CGAffineTransformMakeRotation(horizonObservation.angle));
                    // self.imageView.transform = CGAffineTransformInvert(horizonObservation.transform);
                }
            }
            let handler = VNImageRequestHandler.init(cgImage: image.cgImage!, options: [:])
            try handler.perform([request])
        } catch let error {
            ARLog.debug(error)
        }
    }
}
