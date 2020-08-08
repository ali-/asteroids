//
//  ViewController.swift
//

import UIKit
import SceneKit

class ViewController: UIViewController, SCNSceneRendererDelegate {

	var scene = SCNScene()
	var playerLocation = 1 // [ LEFT(0), MID(1), RIGHT(2) ]
	var playerNode = SCNNode()
	var thrusterNode = SCNNode()
	var sceneView = SCNView()
	var score = 0
	var scoreLabel = UILabel()
	var health = 3
	var healthLabel = UILabel()
	
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
		let move = SCNAction.move(by: SCNVector3(0, 0, -300), duration: 0.15)
		let material = SCNMaterial()
		material.diffuse.contents = UIImage(named: Bundle.main.path(forResource: "laser", ofType: "jpg")!)
		sphere.materials = [material]
		
		let bullet = SCNNode(geometry: sphere)
		scene.rootNode.addChildNode(bullet)
		bullet.eulerAngles = SCNVector3(90, 0, 0)
		bullet.position = SCNVector3(playerNode.position.x, playerNode.position.y-10, playerNode.position.z)
		bullet.physicsBody?.isAffectedByGravity = false
		bullet.runAction(move, completionHandler: {
			bullet.removeFromParentNode()
		})
	}
	
	func drawScene() {
		sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
		
		// GUI
		healthLabel = UILabel(frame: CGRect(x: 20, y: 40, width: view.frame.width-40, height: 30))
		healthLabel.text = "\(health) HP"
		healthLabel.textAlignment = .right
		healthLabel.textColor = .systemGreen
		sceneView.addSubview(healthLabel)
		scoreLabel = UILabel(frame: CGRect(x: 20, y: 40, width: view.frame.width-40, height: 30))
		scoreLabel.text = "Score: \(score)"
		sceneView.addSubview(scoreLabel)
		
		// Camera
		let cameraNode = SCNNode()
		cameraNode.camera = SCNCamera()
		cameraNode.position = SCNVector3(0, 50, 120)
		cameraNode.eulerAngles = SCNVector3(25, 0, 0)
		cameraNode.camera?.zFar = 500
		scene.rootNode.addChildNode(cameraNode)
		
		// Player
		//let box = SCNBox(width: 10, height: 10, length: 10, chamferRadius: 0)
		let ship = SCNScene(named: "ship.dae")!
		playerNode = ship.rootNode.childNode(withName: "fuselage", recursively: true)!
		playerNode.position = SCNVector3(0, 0, 0)
		playerNode.eulerAngles = SCNVector3(55, 0, 0)
		scene.rootNode.addChildNode(playerNode)
		thrusterNode = scene.rootNode.childNode(withName: "thruster", recursively: true)!
		thrusterNode.position = SCNVector3(0, 0, 10)
		
		// Effects
		let particleNode = scene.rootNode.childNode(withName: "stars", recursively: true)!
		particleNode.position = SCNVector3(0, 50, 50)
		particleNode.eulerAngles = SCNVector3(-cameraNode.eulerAngles.x, 0, 0)
		
		// Enemies
		
		
		// Setup
		sceneView.allowsCameraControl = false
		sceneView.backgroundColor = .white
		sceneView.scene = scene
	}
	
	func updateHealth() {
		healthLabel.text = "\(health) HP"
		switch health {
			case 2:
				healthLabel.textColor = .white
				break
			case 1:
				healthLabel.textColor = .systemRed
				break
			default:
				healthLabel.textColor = .systemGreen
				break
		}
	}
	
	func updateScore() {
		scoreLabel.text = "Score: \(score)"
	}

	@objc func tap() {
		score += 1
		if health > 1 { health -= 1 } else { health = 3 }
		updateHealth()
		updateScore()
		createBullet()
	}

	@objc func swipe(gesture: UIGestureRecognizer) {
		if let swipeGesture = gesture as? UISwipeGestureRecognizer {
			switch swipeGesture.direction {
				case UISwipeGestureRecognizer.Direction.right:
					if playerLocation < 2 {
						let move = SCNAction.move(by: SCNVector3(15, 0, 0), duration: 0.1)
						playerNode.runAction(move)
						thrusterNode.runAction(move)
						playerLocation += 1
					}
				case UISwipeGestureRecognizer.Direction.left:
					if playerLocation > 0 {
						let move = SCNAction.move(by: SCNVector3(-15, 0, 0), duration: 0.1)
						playerNode.runAction(move)
						thrusterNode.runAction(move)
						playerLocation -= 1
					}
				default:
					break
			}
		}
	}
	
}

