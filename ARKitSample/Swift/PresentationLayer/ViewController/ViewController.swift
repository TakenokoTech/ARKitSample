//
//  ViewController.swift
//  ARKitSample
//
//  Created by たけのこ on 2018/11/28.
//  Copyright © 2018 たけのこ. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var imageMaker: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var label2: UILabel!
    
    private let viewModel: ViewModel = ViewModel()
    private var recordingButton: RecordingButton!
    private var markerMode = MarkerMode.white
    private var timer: Timer!
    private var planes: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        // Create a new scene
        // let scene = SCNScene(named: "art.scnassets/ship.scn")!
        // sceneView.scene = scene
        // sceneView.scene = SCNScene()
        // sceneView.scene.rootNode.addChildNode(viewModel.createNode())
        
        // Setup UI
        //self.recordingButton = RecordingButton(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        timer.fire()
        configuration.planeDetection = .horizontal // 平面の検出を有効化する
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - IBAction
    
    @IBAction func tapToggleMaker(_ sender: Any) {
        switch markerMode {
        case .white:
            markerMode = .black
            imageMaker.image = UIImage(named: "Landmark_Black")
        case .black:
            markerMode = .none
            imageMaker.image = UIImage(named: "")
        case .none:
            markerMode = .white
            imageMaker.image = UIImage(named: "Landmark_White")
        }
    }
    
    // 計測開始
    @IBAction func beginMeasure(_ sender: Any) {
        if let position = viewModel.getCenter(sceneView) {
            for node in sceneView.scene.rootNode.childNodes {
                node.removeFromParentNode()
            }
            viewModel.startPosition = position
            viewModel.isMeasuring = true
            
            let sphereNode = viewModel.createSphereNode(position: viewModel.startPosition, color: UIColor.red)
            sceneView.scene.rootNode.addChildNode(sphereNode)
        }
    }
    
    @IBAction func touchUpInside(_ sender: Any) {
        viewModel.endMeasure(sceneView)
    }
    
    @IBAction func touchUpOutside(_ sender: Any) {
        viewModel.endMeasure(sceneView)
    }
    
    // 計測中に円柱の描画を更新する
    @objc func update(tm: Timer) {
        if viewModel.isMeasuring {
            if let endPosition = viewModel.getCenter(sceneView) {
                let position = SCNVector3Make(
                    endPosition.x - viewModel.startPosition.x,
                    endPosition.y - viewModel.startPosition.y,
                    endPosition.z - viewModel.startPosition.z
                )
                let distance = sqrt(position.x*position.x + position.y*position.y + position.z*position.z)
                label.text = String.init(format: "%.2fm", arguments: [distance])
                
                viewModel.refreshCylinderNode(sceneView, endPosition: endPosition)
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        viewModel.renderAnchor(node, anchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
    }
}

