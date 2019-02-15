//
//  StoryViewController.swift
//  ARKit-Demo
//
//  Created by Alejandro Mendoza on 2/12/19.
//  Copyright © 2019 Alejandro Mendoza. All rights reserved.
//

import UIKit
import ARKit

enum gameState {
    case selectingPlane
    case viewingStory
}

class StoryViewController: UIViewController{

    @IBOutlet weak var crosshair: UIView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var informationView: UIView!
    @IBOutlet weak var objectName: UILabel!
    @IBOutlet weak var objectDescription: UILabel!
    
    var characterFace: UIImage? = nil
    
    var gameState: gameState = .selectingPlane
    
    var boat: SCNNode? = nil
    var island: SCNNode? = nil
    var sea: SCNNode? = nil
    var character: SCNNode? = nil
    
    var storyAnchorExtent: simd_float3? = nil
    
    var debugPlanes = [SCNNode]()
    
    var viewCenter: CGPoint {
        let viewBounds = view.bounds
        return CGPoint(x: viewBounds.width / 2.0, y: viewBounds.height / 2.0)
    }
    
    let objectInformation: [String: (String, String)] = ["Green_platform": ("Pasto", "Hierba que come el ganado en el campo."), "Island":("Isla", "Porción de tierra rodeada de agua por todas partes"), "Boat":("Barco","Profesor con el que es facíl aprobar la materia"), "Tree":("Árbol", "Planta de tronco leñoso, grueso y elevado que se ramifica a cierta altura del suelo formando la copa."), "propeller":("Aspas","Elemento formado por dos palos que se atraviesan entre sí formando una cruz"), "Mill":("Molino","Construcción en forma de torre donde está instalada esta máquina")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        crosshair.layer.cornerRadius = 5
        informationView.isHidden = true
        
        loadSceneModels()
        setupConfiguration()
    }
    
    func setupConfiguration(){
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        sceneView.delegate = self
        
        sceneView.debugOptions = .showFeaturePoints
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .selectingPlane {
            if let hit = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent]).first{
                
                let hittedAnchor = hit.anchor as? ARPlaneAnchor
                
                storyAnchorExtent = hittedAnchor?.extent
                
                sceneView.session.add(anchor: ARAnchor.init(transform: hit.worldTransform))
                sceneView.debugOptions = []
                
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = []
                
                sceneView.session.run(configuration)
                
                gameState = .viewingStory
                removeDebugPlanes()
                
            }
        }
        
    }
    
    func loadSceneModels(){
        let storyScene = SCNScene(named: "StoryAssets.scnassets/StoryScene.scn")!
        
        for childNode in storyScene.rootNode.childNodes {
            if let name = childNode.name {
                switch name {
                case "Boat":
                    boat = childNode
                case "Island":
                    island = childNode
                case "Sea":
                    sea = childNode
                case "Character":
                    character = childNode
                default:
                    continue
                }
            }
        }
        
    }
    
    func removeDebugPlanes(){
        for debugPlaneNode in debugPlanes {
            debugPlaneNode.removeFromParentNode()
        }
        debugPlanes = []
    }
    

}

extension StoryViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let plane = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
            debugPlanes.append(plane)
            
            DispatchQueue.main.async {
                node.addChildNode(plane)
            }
        }
        else {
            DispatchQueue.main.async {
                [unowned self] in
                self.sea?.position = SCNVector3(0, 0, 0)
                
                self.island?.position = SCNVector3(0, 0, 0)
                self.island?.scale = SCNVector3(0.15, 0.15, 0.15)
                
                if let extent = self.storyAnchorExtent {
                    self.sea?.scale = SCNVector3(extent.x/12.0, 0, extent.z/12.0)
                }
                
                let rotatingNode = SCNNode()
                rotatingNode.position = SCNVector3(0, 0, 0)
                rotatingNode.scale = SCNVector3(0.5, 0.5, 0.5)
                
                let action = SCNAction.rotateBy(x: 0, y: CGFloat(GLKMathDegreesToRadians(-360)), z: 0, duration: 15)
                let forever = SCNAction.repeatForever(action)
                
                rotatingNode.runAction(forever)
                
                self.boat?.position = SCNVector3(0.2, 0.04, 0.2)
                self.boat?.scale = SCNVector3(0.2, 0.09, 0.03)
                
                self.character?.position = SCNVector3(0.2, 0.02, 0.2)
                self.character?.scale = SCNVector3(0.06, 0.06, 0.06)
                
                
                rotatingNode.addChildNode(self.character!)
                rotatingNode.addChildNode(self.boat!)
                
                
                node.addChildNode(rotatingNode)
                node.addChildNode(self.sea!)
                node.addChildNode(self.island!)
                
//                if let characterImage = self.characterFace {
//                    let characterFaceNode = SCNNode(geometry: SCNSphere(radius: 0.3))
//
//                    characterFaceNode.geometry?.materials.first?.diffuse.contents = characterImage
//                   
//
//                    characterFaceNode.position = SCNVector3(0, 0.4, 0)
//                    node.addChildNode(characterFaceNode)
//                }
            }
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        if node.childNodes.count > 0 {
            updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            [unowned self] in
            switch self.gameState{
            case .selectingPlane:
                if let _ = self.sceneView?.hitTest(self.viewCenter, types: [.existingPlaneUsingExtent]).first {
                    self.crosshair.backgroundColor = UIColor.green
                }
                else {
                    self.crosshair.backgroundColor = UIColor.lightGray
                }
            case .viewingStory:
                
                if let hit = self.sceneView.hitTest(self.viewCenter, options: nil).first {
                    guard let nodeName = hit.node.name else {return}
                    
                    if let nodeData = self.objectInformation[nodeName]{
                        self.crosshair.backgroundColor = UIColor.green
                        self.objectName.text = nodeData.0
                        self.objectDescription.text = nodeData.1
                        self.informationView.isHidden = false
                    }
                }
                else {
                    self.informationView.isHidden = true
                    self.crosshair.backgroundColor = UIColor.lightGray
                }
            }
        }
    }
    
}
