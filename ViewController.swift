//
//  ViewController.swift
//

import UIKit
import SceneKit

var scene: SCNScene!
var sceneView: SCNView!
var playerLocation = 1
var playerNode: SCNNode!
var thrusterNode: SCNNode!
var score = 0
var scoreLabel: UILabel!
var health = 3
var healthLabel: UILabel!
var debugLabel: UILabel!
var objectCount = 0

class ViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Scene
		scene = SCNScene(named: "starfield.scn")!
		scene.physicsWorld.contactDelegate = self
		sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
		sceneView.allowsCameraControl = false
		sceneView.delegate = self
		sceneView.scene = scene
		drawScene()
		view.addSubview(sceneView)
		
		// Controls
		let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
		swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
		view.addGestureRecognizer(swipeLeft)
		let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipe))
		swipeRight.direction = UISwipeGestureRecognizer.Direction.right
		view.addGestureRecognizer(swipeRight)
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(createLaser))
		doubleTap.numberOfTapsRequired = 2
		view.addGestureRecognizer(doubleTap)
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
		debugLabel = UILabel(frame: CGRect(x: 20, y: 70, width: view.frame.width-40, height: 30))
		debugLabel.text = ""
		sceneView.addSubview(debugLabel)
		
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
		playerNode.physicsBody?.categoryBitMask = PhysicsObject.player.rawValue
		playerNode.physicsBody?.collisionBitMask = PhysicsObject.asteroid.rawValue | PhysicsObject.enemy.rawValue
		playerNode.physicsBody?.contactTestBitMask = PhysicsObject.contact.rawValue
		thrusterNode = scene.rootNode.childNode(withName: "thruster", recursively: true)!
		thrusterNode.position = SCNVector3(0, 0, 10)
		scene.rootNode.addChildNode(playerNode)
		
		// Effects
		let particleNode = scene.rootNode.childNode(withName: "stars", recursively: true)!
		particleNode.position = SCNVector3(0, 50, 50)
		particleNode.eulerAngles = SCNVector3(-cameraNode.eulerAngles.x, 0, 0)
		
		createObject(-1)
		createObject(0)
		createObject(1)
	}
	
	func updateHealth() {
		healthLabel.text = "\(health) HP"
		switch health {
			case 2: healthLabel.textColor = .white; break
			case 1: healthLabel.textColor = .systemRed; break
			default: healthLabel.textColor = .systemGreen; break
		}
	}
	
	func createObject(_ position: Int?) {
		// Enemies
		let box = SCNBox(width: 10, height: 10, length: 10, chamferRadius: 0)
		let move = SCNAction.move(by: SCNVector3(0, 0, (800+(score*10))), duration: 5)
		let enemyNode = ObjectNode()
		let x = position == nil ? Int.random(in: -1...1) : position!
		enemyNode.geometry = box
		enemyNode.position = SCNVector3(x*20, 0, -1000+(Int.random(in: -3...3)*20))
		enemyNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: enemyNode))
		enemyNode.physicsBody?.categoryBitMask = PhysicsObject.enemy.rawValue
		enemyNode.physicsBody?.contactTestBitMask = PhysicsObject.contact.rawValue
		enemyNode.physicsBody?.isAffectedByGravity = false
		enemyNode.name = "enemy"
		enemyNode.runAction(move, completionHandler: { enemyNode.destroy() })
		scene.rootNode.addChildNode(enemyNode)
		var delay = 5.0 + Double.random(in: -1...1) - Double(score/5)
		if delay < 2 { delay = Double.random(in: 1...2) }
		DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
			self?.createObject(nil)
		}
	}
	
	func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
		score += 1
		if contact.nodeA.name != "player" {
			if contact.nodeA.name == "enemy" { (contact.nodeA as? ObjectNode)?.destroy() }
			else { contact.nodeA.removeFromParentNode() }
		}
		if contact.nodeB.name != "player" {
			if contact.nodeB.name == "enemy" { (contact.nodeB as? ObjectNode)?.destroy() }
			else { contact.nodeB.removeFromParentNode() }
		}
	}

	@objc func createLaser() {
		let plane = SCNBox(width: 1, height: 0.1, length: 10, chamferRadius: 0)
		let move = SCNAction.move(by: SCNVector3(0, 0, 0), duration: 0.5)
		let material = SCNMaterial()
		material.diffuse.contents = UIImage(named: Bundle.main.path(forResource: "laser", ofType: "jpg")!)
		plane.materials = [material]
		let laserNode = SCNNode(geometry: plane)
		scene.rootNode.addChildNode(laserNode)
		laserNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: laserNode))
		laserNode.physicsBody?.categoryBitMask = PhysicsObject.laser.rawValue
		laserNode.physicsBody?.collisionBitMask = PhysicsObject.asteroid.rawValue | PhysicsObject.enemy.rawValue
		laserNode.physicsBody?.contactTestBitMask = PhysicsObject.contact.rawValue
		laserNode.physicsBody?.isAffectedByGravity = false
		laserNode.physicsBody?.applyForce(SCNVector3(0, 0, -300), asImpulse: true)
		laserNode.position = SCNVector3(playerNode.position.x, playerNode.position.y-0.1, playerNode.position.z+5)
		laserNode.name = "laser"
		laserNode.runAction(move, completionHandler: { laserNode.removeFromParentNode() })
	}

	@objc func swipe(gesture: UIGestureRecognizer) {
		if let swipeGesture = gesture as? UISwipeGestureRecognizer {
			switch swipeGesture.direction {
				case UISwipeGestureRecognizer.Direction.right:
					if playerLocation < 2 {
						let move = SCNAction.move(by: SCNVector3(20, 0, 0), duration: 0.1)
						playerNode.runAction(move)
						thrusterNode.runAction(move)
						playerLocation += 1
					}
				case UISwipeGestureRecognizer.Direction.left:
					if playerLocation > 0 {
						let move = SCNAction.move(by: SCNVector3(-20, 0, 0), duration: 0.1)
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

func updateScore() {
	DispatchQueue.main.async { scoreLabel.text = "Score: \(score)" }
}

class ObjectNode: SCNNode {
	func destroy() {
		updateScore()
		removeFromParentNode()
	}
}

enum PhysicsObject: Int {
	case contact = 1
	case player = 2
	case asteroid = 4
	case enemy = 8
	case laser = 16
}
