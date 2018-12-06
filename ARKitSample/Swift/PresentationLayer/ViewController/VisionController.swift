//
//  VisionController.swift
//  ARKitSample
//
//  Created by 竹仲 孝盛 on 2018/12/04.
//  Copyright © 2018年 たけのこ. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary
import UIKit
import Vision
import Photos

class VisionController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var startStopButton: UIButton!
    
    private var viewModel: VideoViewModelProtocol!
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = VideoViewModel(delegate: self)
        
        if let previewLayer = viewModel.initCapture() {
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewModel.stopCapture()
    }
    
    private func render() {
        startStopButton.setTitle(!viewModel.isRecoding ? "start" : "stop", for: UIControl.State.normal)
    }
    
    @IBAction func tapStartStopButton() {
        if !viewModel.isRecoding {
            viewModel.startCapture()
        } else {
            viewModel.stopCapture()
        }
        self.render()
    }
    
    /// 新しいキャプチャの追加で呼ばれる
    ///
    /// - Parameters:
    ///   - captureOutput: captureOutput description
    ///   - sampleBuffer: sampleBuffer description
    ///   - connection: connection description
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        ARLog.debug("captureOutput")
    }
    
    /// ファイルを書き出し完了
    ///
    /// - Parameters:
    ///   - output: output description
    ///   - outputFileURL: outputFileURL description
    ///   - connections: connections description
    ///   - error: error description
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        ARLog.debug("fileOutput \(outputFileURL) \(error.debugDescription)")
        viewModel.outputCapture(url: outputFileURL, callback: { _ in
             self.dismiss(animated: true, completion: nil)
        })
    }
}
