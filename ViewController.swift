//
//  ViewController.swift
//

import UIKit
import SceneKit

class ViewController: UIViewController, SCNSceneRendererDelegate {

	var scene = SCNScene()
	var playerLocation = 1 // [ LEFT(0), MID(1), RIGHT(2) ]
	var playerNode = SCNNode()
	var sceneView = SCNView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		scene = SCNScene(named: "starfield.scn")!
		view.backgroundColor = .white
		drawScene()
		view.addSubview(sceneView)
		
		// Controls
		let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
		swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
		view.addGestureRecognizer(swipeLeft)
		let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
		swipeRight.direction = UISwipeGestureRecognizer.Direction.right
		view.addGestureRecognizer(swipeRight)
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(tap))
		doubleTap.numberOfTapsRequired = 2
		view.addGestureRecognizer(doubleTap)
	}

	func createBullet() {
		let sphere = SCNCylinder(radius: 1, height: 10)
		let move = SCNAction.move(by: SCNVector3Make(0, 20, 0), duration: 2)
		let material = SCNMaterial()
		material.diffuse.contents = UIImage(named: Bundle.main.path(forResource: "laser", ofType: "jpg")!)
		sphere.materials = [material]
		
		let bullet = SCNNode(geometry: sphere)
		scene.rootNode.addChildNode(bullet)
		bullet.eulerAngles = SCNVector3Make(90, 0, 0)
		bullet.position = playerNode.position
		bullet.physicsBody?.isAffectedByGravity = false
		bullet.runAction(move, completionHandler: {
			bullet.removeFromParentNode()
		})
	}
	
	func drawScene() {
		sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
		
		let label = UILabel(frame: CGRect(x: 20, y: 40, width: view.frame.width-40, height: 30))
		label.text = "Points: 0"
		sceneView.addSubview(label)
		
		// Camera
		let cameraNode = SCNNode()
		cameraNode.camera = SCNCamera()
		cameraNode.position = SCNVector3Make(0, 30, 100)
		//cameraNode.eulerAngles = SCNVector3Make(0, 0, 0)
		scene.rootNode.addChildNode(cameraNode)
		
		// Player
		let box = SCNBox(width: 10, height: 10, length: 10, chamferRadius: 0)
		playerNode = SCNNode(geometry: box)
		playerNode.position = SCNVector3Make(0, 0, 0)
		scene.rootNode.addChildNode(playerNode)
		
		// Effects
		let particleNode = scene.rootNode.childNode(withName: "stars", recursively: true)!
		particleNode.position = SCNVector3Make(0, 30, 75)
		
		sceneView.allowsCameraControl = false
		sceneView.backgroundColor = .white
		sceneView.scene = scene
	}

	@objc func tap() {
		print("Double tap")
		createBullet()
	}

	@objc func swipe(gesture: UIGestureRecognizer) {
		if let swipeGesture = gesture as? UISwipeGestureRecognizer {
			switch swipeGesture.direction {
				case UISwipeGestureRecognizer.Direction.right:
					if playerLocation < 2 {
						let move = SCNAction.move(by: SCNVector3Make(15, 0, 0), duration: 0.1)
						playerNode.runAction(move)
						playerLocation += 1
					}
				case UISwipeGestureRecognizer.Direction.left:
					if playerLocation > 0 {
						let move = SCNAction.move(by: SCNVector3Make(-15, 0, 0), duration: 0.1)
						playerNode.runAction(move)
						playerLocation -= 1
					}
				default:
					break
			}
		}
	}
	
}

