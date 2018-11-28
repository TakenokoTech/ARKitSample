//
//  ViewModel.swift
//  ARKitSample
//
//  Created by たけのこ on 2018/11/28.
//  Copyright © 2018 たけのこ. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit
import ReplayKit

enum MarkerMode {
    case white
    case black
    case none
}

class ViewModel {
    
    private var _startPosition: SCNVector3!
    private var _isMeasuring = false
    private var cylinderNode: SCNNode?
    
    public var startPosition: SCNVector3 { get { return _startPosition } set { _startPosition = newValue}}
    public var isMeasuring: Bool { get { return _isMeasuring } set { _isMeasuring = newValue}}
    
    public func createNode() -> SCNNode {
        let node = SCNNode()
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "brick")
        node.geometry = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        node.geometry?.materials = [material]
        node.position = SCNVector3(0, 0, -0.5)
        return node
    }
    
    // 球体のノードの作成
    func createSphereNode(position: SCNVector3, color: UIColor) -> SCNNode {
        let sphere = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = color
        sphere.materials = [material]
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
        return sphereNode
    }
    
    // 線のノードの作成
    func createLineNode(startPosition: SCNVector3, endPosition: SCNVector3, color: UIColor) -> SCNNode {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [startPosition, endPosition])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let line = SCNGeometry(sources: [source], elements: [element])
        line.firstMaterial?.lightingModel = SCNMaterial.LightingModel.blinn
        let lineNode = SCNNode(geometry: line)
        lineNode.geometry?.firstMaterial?.diffuse.contents = color
        return lineNode
    }
    
    // 円柱のノードの作成
    func createCylinderNode(startPosition: SCNVector3, endPosition: SCNVector3, radius: CGFloat , color: UIColor, transparency: CGFloat) -> SCNNode {
        let height = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(startPosition), SCNVector3ToGLKVector3(endPosition)))
        let cylinderNode = SCNNode()
        cylinderNode.eulerAngles.x = Float(Double.pi / 2)
        let cylinderGeometry = SCNCylinder(radius: radius, height: height)
        cylinderGeometry.firstMaterial?.diffuse.contents = color
        let cylinder = SCNNode(geometry: cylinderGeometry)
        cylinder.position.y = Float(-height/2)
        cylinderNode.addChildNode(cylinder)
        let node = SCNNode()
        let targetNode = SCNNode()
        if (startPosition.z < 0.0 && endPosition.z > 0.0) {
            node.position = endPosition
            targetNode.position = startPosition
        } else {
            node.position = startPosition
            targetNode.position = endPosition
        }
        node.addChildNode(cylinderNode)
        node.constraints = [ SCNLookAtConstraint(target: targetNode) ]
        return node
    }
    
    // 計測終了
    func endMeasure(_ sceneView: ARSCNView) {
        if !isMeasuring { return }
        isMeasuring = false
        if let endPosition = getCenter(sceneView) {
            let sphereNode = createSphereNode(position: endPosition, color: UIColor.red)
            sceneView.scene.rootNode.addChildNode(sphereNode)
            let centerPosition = Center(startPosition: startPosition, endPosition: endPosition)
            let centerSphereNode = createSphereNode(position: centerPosition, color: UIColor.orange)
            sceneView.scene.rootNode.addChildNode(centerSphereNode)
            let lineNode = createLineNode(startPosition: startPosition, endPosition: endPosition, color: UIColor.white)
            sceneView.scene.rootNode.addChildNode(lineNode)
            refreshCylinderNode(sceneView, endPosition: endPosition)
        }
    }
    // 画面の中央を取得する
    func getCenter(_ sceneView: ARSCNView) -> SCNVector3? {
        let touchLocation = sceneView.center
        let hitResults = sceneView.hitTest(touchLocation, types: [.featurePoint])
        if !hitResults.isEmpty {
            if let hitTResult = hitResults.first {
                return SCNVector3(hitTResult.worldTransform.columns.3.x, hitTResult.worldTransform.columns.3.y, hitTResult.worldTransform.columns.3.z)
            }
        }
        return nil
    }
    
    // 2点間の中心座標を取得する
    func Center(startPosition: SCNVector3, endPosition: SCNVector3) -> SCNVector3 {
        let x = endPosition.x - startPosition.x
        let y = endPosition.y - startPosition.y
        let z = endPosition.z - startPosition.z
        return SCNVector3Make(endPosition.x - x/2, endPosition.y - y/2, endPosition.z - z/2)
    }
    
    // 円柱の更新
    func refreshCylinderNode(_ sceneView: ARSCNView,endPosition: SCNVector3) {
        if let node = cylinderNode {
            node.removeFromParentNode()
        }
        cylinderNode = createCylinderNode(startPosition: startPosition, endPosition: endPosition, radius: 0.001, color: UIColor.yellow, transparency: 0.5)
        sceneView.scene.rootNode.addChildNode(cylinderNode!)
    }
}

extension RecordingButton: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        DispatchQueue.main.async { [unowned previewController] in
            previewController.dismiss(animated: true, completion: nil)
        }
    }
}
class RecordingButton: UIButton {
    var isRecording = false
    let height:CGFloat = 50.0
    let width:CGFloat = 100.0
    let viewController: UIViewController!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(_ viewController: UIViewController) {
        self.viewController = viewController
        
        super.init(frame: CGRect(x:0, y:0, width:width, height:height))
        
        //        layer.position = CGPoint(x: viewController.view.frame.width/2, y:viewController.view.frame.height - height)
        layer.position = CGPoint(x: width/2, y:viewController.view.frame.height - height)
        
        layer.cornerRadius = 10
        layer.borderWidth = 1
        setTitleColor(UIColor.white, for: .normal)
        
        addTarget(self, action: #selector(tapped), for:.touchUpInside)
        
        setAppearance()
        viewController.view.addSubview(self)
    }
    
    @objc func tapped() {
        if !isRecording {
            isRecording = true
            RPScreenRecorder.shared().startRecording(handler: { (error) in
                print(error)
            })
        } else {
            isRecording = false
            RPScreenRecorder.shared().stopRecording(handler: { (previewViewController, error) in
                previewViewController?.previewControllerDelegate = self
                self.viewController.present(previewViewController!, animated: true, completion: nil)
            })
        }
        setAppearance()
    }
    
    
    func setAppearance() {
        var alpha:CGFloat = 1.0
        var title = "REC"
        if isRecording {
            title = ""
            alpha = 0
        }
        setTitle(title, for: .normal)
        backgroundColor = UIColor(red: 0.7, green: 0, blue: 0, alpha: alpha)
        layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: alpha).cgColor
    }
}
