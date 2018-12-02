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

enum CollisionBitmask: Int {
    case ball = 1
    case floor = 2
}

protocol IViewModel {
    
}

class ViewModel : IViewModel {
    
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
    
    //
    func renderAnchor(_ parentNode: SCNNode, _ anchor: ARAnchor) {
        ARLog.funcIn(); defer { ARLog.funcOut() }
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        ARLog.debug("x: \(planeAnchor.center.x)")
        ARLog.debug("y: \(planeAnchor.center.y)")
        ARLog.debug("z: \(planeAnchor.center.z)")
        
        let planeNode = CustomPlane.greenSheet(anchor: planeAnchor)
        planeNode.name = "plane"
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform =  SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        parentNode.addChildNode(planeNode)

        let textNode = CustomPlane.text(anchor: planeAnchor)
        textNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        textNode.transform =  SCNMatrix4MakeRotation(/* -Float.pi / 2 */0, 0.3, 0, 0)
        // parentNode.addChildNode(textNode)
    
        let size: Float = 1 ;
        for indexX in 0...0 { for indexY in 0...0 { for indexZ in 0...0 {
        // for indexX in -2...2 { for indexY in 0...0 { for indexZ in -2...2 {
            let cubeNode = CustomPlane.cubeXcm(size: size)
            cubeNode.name = "box"
            cubeNode.position = SCNVector3Make(planeAnchor.center.x + Float(indexX) * size, Float(indexY)*size, planeAnchor.center.z + Float(indexZ)*size)
            // parentNode.addChildNode(cubeNode)
        }}}
        
        let ballNode = CustomPlane.baseball()
        ballNode.name = "ball"
        ballNode.position = SCNVector3Make(planeAnchor.center.x, 2, planeAnchor.center.z)
        // parentNode.addChildNode(ballNode)
        
        ARLog.dumpNode(parentNode)
    }
}

// MARK: - Custom Plane

class CustomPlane {
    
    static func cubeXcm(size: Float) -> SCNNode {
        // Maaterial
        let material = SCNMaterial()
        material.diffuse.contents = randomColor().withAlphaComponent(1)
        // Plane
        let node = SCNNode()
        node.geometry = SCNBox(width: CGFloat(size), height: 0.3 /*CGFloat(size)*/, length: CGFloat(size), chamferRadius: 0)
        node.geometry?.materials = [material]
        // PhysicsBody
        node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: node.geometry!, options: nil))
        node.physicsBody?.contactTestBitMask = CollisionBitmask.ball.rawValue
        node.physicsBody?.collisionBitMask = CollisionBitmask.ball.rawValue
        node.physicsBody?.categoryBitMask = CollisionBitmask.floor.rawValue
        return node
    }
    
    static func greenSheet(anchor: ARPlaneAnchor) -> SCNNode {
        // Maaterial
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor.green.withAlphaComponent(1)
        // Plane
        let node = SCNNode()
        // node.geometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        node.geometry = SCNBox(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z), length: 0.1, chamferRadius: 0)
        node.geometry?.materials = [planeMaterial]
        // PhysicsBody
        node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: node.geometry!, options: nil))
        node.physicsBody?.contactTestBitMask = CollisionBitmask.ball.rawValue
        node.physicsBody?.collisionBitMask = CollisionBitmask.ball.rawValue
        node.physicsBody?.categoryBitMask = CollisionBitmask.floor.rawValue
        return node;
    }
    
    static func text(anchor: ARPlaneAnchor) -> SCNNode {
        let pos = String.init(format: "( %.2f, %.2f)", arguments: [CGFloat(anchor.extent.x), CGFloat(anchor.extent.z)])
        let text = SCNText(string: pos, extrusionDepth: 0.001)
        text.font = UIFont(name: "HiraKakuProN-W6", size: 0.1);
        return SCNNode(geometry: text)
    }
    
    static func baseball() -> SCNNode {
        // Maaterial
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(1)
        // Plane
        let node = SCNNode()
        // node.geometry = SCNSphere(radius: CGFloat(0.074))
        node.geometry = SCNSphere(radius: CGFloat(0.3))
        node.geometry?.materials = [material]
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: node.geometry!, options: nil))
        node.physicsBody?.categoryBitMask = CollisionBitmask.ball.rawValue
        return node
    }
    
    static func staticBall () -> SCNNode {
        // Maaterial
        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.yellow.withAlphaComponent(0.5)
        // Plane
        let node = SCNNode()
        node.geometry = SCNSphere(radius: CGFloat(0.1))
        node.geometry?.materials = [material]
        node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: node.geometry!, options: nil))
        return node
    }

    private static func randomColor() -> UIColor {
        switch Int.random(in: 1 ... 1) {
        case 1: return UIColor.red
        case 2: return UIColor.green
        case 3: return UIColor.blue
        case 4: return UIColor.cyan
        case 5: return UIColor.yellow
        case 6: return UIColor.magenta
        case 7: return UIColor.orange
        case 8: return UIColor.purple
        default: return UIColor.brown
        }
    }
}



