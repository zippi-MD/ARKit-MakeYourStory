//
//  ViewController.swift
//  ARKit-Demo
//
//  Created by Alejandro Mendoza on 2/12/19.
//  Copyright © 2019 Alejandro Mendoza. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var leftEyeImage: UIImageView!
    @IBOutlet weak var rightEyeImage: UIImageView!
    @IBOutlet weak var mouthImage: UIImageView!
    @IBOutlet weak var characterView: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if !ARFaceTrackingConfiguration.isSupported {
            performSegue(withIdentifier: "StoryViewSegue", sender: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !ARFaceTrackingConfiguration.isSupported {
            performSegue(withIdentifier: "StoryViewSegue", sender: nil)
        }
        
        setupFaceTracking()
        
        mouthImage.isHidden = true
        leftEyeImage.isHidden = true
        rightEyeImage.isHidden = true
    }
    
    func setupFaceTracking(){
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
        sceneView.delegate = self
    }
    

    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {return}
        
        let jawOpen = faceAnchor.blendShapes[.jawOpen] as! Double
        let blinkLeft = faceAnchor.blendShapes[.eyeBlinkLeft] as! Double
        let blinkRight = faceAnchor.blendShapes[.eyeBlinkRight] as! Double
                
        DispatchQueue.main.async {
            if(jawOpen > 0.4){
                self.mouthImage.isHidden = false
            }
            else {
                self.mouthImage.isHidden = true
            }
            
            if(blinkLeft > 0.4){
                self.leftEyeImage.isHidden = false
            }
            else {
                self.leftEyeImage.isHidden = true
            }
            
            if(blinkRight > 0.4){
                self.rightEyeImage.isHidden = false
            }
            else {
                self.rightEyeImage.isHidden = true
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc: StoryViewController = segue.destination as! StoryViewController
        
        let renderer = UIGraphicsImageRenderer(size: characterView.frame.size)
        let characterFace = renderer.image { (ctx) in
            characterView.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        vc.characterFace = characterFace
        
        
    }
    
    @IBAction func showStoryTapped(_ sender: Any) {
        performSegue(withIdentifier: "StoryViewSegue", sender: nil)
    }
    


}

