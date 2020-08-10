//
//  ViewController.swift
//

import UIKit
import SceneKit

class ViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

	var scene: SCNScene!
	var sceneView: SCNView!
	var playerLocation = 1
	var playerNode: SCNNode!
	var thrusterNode: SCNNode!
	var score = 0
	var scoreLabel: UILabel!
	var health = 3
	var healthLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Scene
		scene = SCNScene(named: "starfield.scn")!
		sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
		sceneView.allowsCameraControl = false
		sceneView.delegate = self
		sceneView.scene = scene
		sceneView.scene?.physicsWorld.contactDelegate = self
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
	
	func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
		print("Contact")
	}
	
	func drawScene() {
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
		cameraNode.camera?.zFar = 1000
		scene.rootNode.addChildNode(cameraNode)
		
		// Player
		let ship = SCNScene(named: "ship.dae")!
		playerNode = ship.rootNode.childNode(withName: "fuselage", recursively: true)!
		playerNode.name = "player"
		playerNode.position = SCNVector3(0, 0, 0)
		playerNode.eulerAngles = SCNVector3(55, 0, 0)
		thrusterNode = scene.rootNode.childNode(withName: "thruster", recursively: true)!
		thrusterNode.position = SCNVector3(0, 0, 10)
		scene.rootNode.addChildNode(playerNode)
		
		// Effects
		let particleNode = scene.rootNode.childNode(withName: "stars", recursively: true)!
		particleNode.position = SCNVector3(0, 50, 50)
		particleNode.eulerAngles = SCNVector3(-cameraNode.eulerAngles.x, 0, 0)
		
		// Enemies
		let box = SCNBox(width: 10, height: 10, length: 10, chamferRadius: 0)
		let enemyNode = SCNNode(geometry: box)
		enemyNode.position = SCNVector3(0, 0, -300)
		enemyNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: enemyNode))
		enemyNode.physicsBody?.categoryBitMask = PhysicsObject.enemy.rawValue
		enemyNode.physicsBody?.isAffectedByGravity = false
		enemyNode.name = "enemy"
		scene.rootNode.addChildNode(enemyNode)
	}
	
	func updateHealth() {
		healthLabel.text = "\(health) HP"
		switch health {
			case 2: healthLabel.textColor = .white; break
			case 1: healthLabel.textColor = .systemRed; break
			default: healthLabel.textColor = .systemGreen; break
		}
	}
	
	func updateScore() {
		scoreLabel.text = "Score: \(score)"
	}

	func createBullet() {
		let plane = SCNBox(width: 1, height: 0.1, length: 10, chamferRadius: 0)
		let move = SCNAction.move(by: SCNVector3(0, 0, 0), duration: 0.25)
		let material = SCNMaterial()
		material.diffuse.contents = UIImage(named: Bundle.main.path(forResource: "laser", ofType: "jpg")!)
		plane.materials = [material]
		let laserNode = SCNNode(geometry: plane)
		scene.rootNode.addChildNode(laserNode)
		laserNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: laserNode))
		laserNode.physicsBody?.categoryBitMask = PhysicsObject.laser.rawValue
		laserNode.physicsBody?.collisionBitMask = PhysicsObject.asteroid.rawValue | PhysicsObject.enemy.rawValue
		laserNode.physicsBody?.contactTestBitMask = PhysicsObject.asteroid.rawValue | PhysicsObject.enemy.rawValue
		laserNode.physicsBody?.isAffectedByGravity = false
		laserNode.physicsBody?.applyForce(SCNVector3(0, 0, -250), asImpulse: true)
		laserNode.position = SCNVector3(playerNode.position.x, playerNode.position.y-2, playerNode.position.z+5)
		laserNode.name = "laser"
		laserNode.runAction(move, completionHandler: { laserNode.removeFromParentNode() })
	}
	
	func collisionBetween(objA: SCNNode, objB: SCNNode) {
		if objA.name == "player" {
			health -= 1;
			updateHealth()
			objB.removeFromParentNode()
		}
		if objA.name == "laser" {
			if objB.name == "enemy" {
				// Check health of enemy
			}
			else if objB.name == "asteroid" {
				score += 1;
				updateScore()
				objB.removeFromParentNode()
			}
			objA.removeFromParentNode()
		}
	}

	@objc func tap() {
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

enum PhysicsObject: Int {
	case player = 1
	case asteroid = 2
	case enemy = 4
	case laser = 8
}
