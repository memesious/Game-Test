
//
//  GameScene.swift
//  Game Test
//
//  Created by Игорь Ялынный on 2/2/18.
//  Copyright © 2018 Игорь Ялынный. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion


class GameScene: SKScene, SKPhysicsContactDelegate {
    var starField:SKEmitterNode!
    var player:SKSpriteNode!
    var rocketFire:SKEmitterNode!
    var scoreLabel:SKLabelNode!
    var boost:SKEmitterNode!
    var reloadField = SKSpriteNode(color: UIColor.cyan, size: CGSize(width: 0, height: 5))
    
    var reload = false
    
    var acceleration: CGFloat = 0.0
    
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    let maxDifficulty = 100.0
    var difficulty = 1.0
  
    var deathLabel:SKLabelNode!
    var score:Int = 0{
        didSet{
            scoreLabel.numberOfLines = 3
            scoreLabel.text = "Score: \(score) \nDifficulty: \(difficulty)\nHealth:\(health)"
            difficulty = min(round((difficulty + 0.01)*100)/100, maxDifficulty)
           
            
        }
    }
    var health:Int = 5{
        didSet{
            scoreLabel.text = "Score: \(score) \n Difficulty: \(difficulty)\nHealth:\(health)"
            if health == 0 {
                self.run(SKAction.wait(forDuration: 0.5)){
                    
                    self.deathLabel = SKLabelNode()
                    self.deathLabel.position = CGPoint(x: 0, y: 0)
                    self.deathLabel.fontName = "BradleyHandITCTT-Bold"
                    self.deathLabel.fontColor = UIColor.white
                    self.deathLabel.numberOfLines = 3
                    self.deathLabel.text = "You Died!\nYour score:\(self.score)\nTap the screen to try again"
                    self.addChild(self.deathLabel)
                    self.scene?.view?.isPaused = true
                }
                
            }
        }
    }
    
    
    var aliens = ["Alien4"]
     //var aliens = ["Alien1", "Alien2", "Alien3"]
    var gameTimer:Timer!
    
    //==================Создание битмасков===============================
    let boostCategory:UInt32 = 0x1 << 1
    let alienCategory:UInt32 = 0x1 << 1
    let magicMissleCategory:UInt32 = 0x1 << 0
    let superShuffleCategory:UInt32 = 0x1 << 2
    //===================================================================
    
    
    override func didMove(to view: SKView) {
        
        
       
        respawn()
        physicsWorld.contactDelegate = self
        
        gameTimer = Timer.scheduledTimer(timeInterval: 1.25/difficulty, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data{
                let acceleration = accelerometerData.acceleration
                self .xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
        
        
    }
    var aim:CGFloat!
    func respawn(){
        starField = SKEmitterNode(fileNamed: "StarField")
        starField.position = CGPoint(x: 0, y: 1024)
        starField.zPosition = -1
        starField.advanceSimulationTime(30)
        self.addChild(starField)
        //=============================================
        player = SKSpriteNode(imageNamed: "Shuttle")
        player.position = CGPoint(x: 0, y: -300)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.frame.width / 3)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = superShuffleCategory
        player.physicsBody?.contactTestBitMask = alienCategory
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.usesPreciseCollisionDetection = true
        //==============================================
        
        self.addChild(player)
        
        rocketFire = SKEmitterNode(fileNamed: "EngineFire")
        rocketFire.position = CGPoint(x: player.position.x, y: player.position.y - player.frame.size.height / 2.2)
        self.addChild(rocketFire)
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: 200, y: 380)
        self.addChild(scoreLabel)
        scoreLabel.fontName = "BradleyHandITCTT-Bold"
        scoreLabel.fontColor = UIColor.cyan
        score = 0
        addChild(reloadField)
        reloadField.zPosition = 10
          aim = player.position.x
    }
    
    @objc func addAlien () {
        aliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: aliens) as! [String]
        let alien = SKSpriteNode(imageNamed: aliens[0])
        //boost = SKEmitterNode(fileNamed: "AlienBoost")
        //alien.size.height = alien.size.height/20
        //alien.size.width = alien.size.width/20
        let randomPosition = GKRandomDistribution(lowestValue: -384, highestValue: 384)
        let position = CGFloat(randomPosition.nextInt())
        alien.position = CGPoint(x: position, y: self.frame.size.height/2 + alien.frame.size.height)
        /*boost.position = alien.position
        boost.position.y -= 10
        self.addChild(boost)*/
        //======================Физическая модель пришельцев=========================
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = magicMissleCategory
        alien.physicsBody?.collisionBitMask = 0
        
        /*boost.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        boost.physicsBody?.isDynamic = true
        boost.physicsBody?.categoryBitMask = alienCategory
        boost.physicsBody?.contactTestBitMask = magicMissleCategory
        boost.physicsBody?.collisionBitMask = 0*/
        //==========================================================================
        if self.scene?.isPaused == false{
        self.addChild(alien)
        
        }
        let animationDuration:TimeInterval = TimeInterval(5/difficulty)
        var actionArray = [SKAction] ()
        
        actionArray.append(SKAction.move(to: CGPoint(x: alien.position.x, y: -800), duration: animationDuration))
        actionArray.append(SKAction.run {
            self.difficulty += 0.1
           
        })
        actionArray.append(SKAction.removeFromParent())
        
        
        alien.run(SKAction.sequence(actionArray))
      
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        
        if self.scene?.view?.isPaused == true{
            self.scene?.view?.isPaused = false
            self.score = 0
            self.difficulty = 1
            self.health = 5
            self.deathLabel.removeFromParent()
            self.removeAllChildren()
            self.removeAllActions()
            respawn()
            
        }
        
        
        if !reload{
            fireMissle()
           self.reload = true
            var actionArray = [SKAction] ()
            actionArray.append(SKAction.resize(toWidth: player.frame.width, duration: 0))
            actionArray.append(SKAction.resize(toWidth: 0, duration: TimeInterval(1/difficulty)))
            
            reloadField.run(SKAction.sequence(actionArray))
            self.run(SKAction.wait(forDuration: TimeInterval(1/difficulty))){
                self.reload = false
            }
        }
    }
    var target:CGFloat!
    func fireMissle() {
        let rocketMissle = SKSpriteNode(imageNamed: "missle")
        boost = SKEmitterNode(fileNamed: "AlienBoost")
        boost.position = player.position
        self.addChild(boost)
        self.run(SKAction.wait(forDuration: 1)){
        self.boost.removeFromParent()
        }
       
        rocketMissle.position = player.position
        rocketMissle.position.y += 10
        //=======================Физическая модель ракет===================================
        rocketMissle.physicsBody = SKPhysicsBody(circleOfRadius: rocketMissle.size.height / 2)
        rocketMissle.physicsBody?.isDynamic = true
        rocketMissle.physicsBody?.categoryBitMask = magicMissleCategory
        rocketMissle.physicsBody?.contactTestBitMask = alienCategory
        rocketMissle.physicsBody?.collisionBitMask = 0
        rocketMissle.physicsBody?.usesPreciseCollisionDetection = true
        //=================================================================================
        
        self.addChild(rocketMissle)
        
        let animationDuration:TimeInterval = 0.3
        var actionArray = [SKAction] ()
      
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height/2+20), duration: animationDuration))
            
        actionArray.append(SKAction.removeFromParent())
        rocketMissle.run(SKAction.sequence(actionArray))
      
        
    }
    //======================функция события столкновения и функция, вызываемая первой функцией====================================================================
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & magicMissleCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            missleDidCollideWithAlien(missleNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
        if (firstBody.categoryBitMask == player.physicsBody?.categoryBitMask) || (secondBody.categoryBitMask == player.physicsBody?.categoryBitMask)  {
            playerDidCollideWithAlien(playerNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
 
    }
    
    }
    
    func missleDidCollideWithAlien(missleNode:SKSpriteNode, alienNode:SKSpriteNode){
        //=============================================================================
        
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        //self.run(SKAction.playSoundFileNamed("Explosion.mp3", waitForCompletion: false))
        missleNode.removeFromParent()
        
        alienNode.removeFromParent()
        self.run(SKAction.wait(forDuration: 3)){
            explosion.removeFromParent()
        }
        score += 5
        
        
        
    }
    func playerDidCollideWithAlien(playerNode:SKSpriteNode, alienNode:SKSpriteNode){
        
    let explosion = SKEffectNode(fileNamed: "playerExplosion")
        explosion?.position = player.position
        self.addChild(explosion!)
        if playerNode == player.physicsBody{
        alienNode.removeFromParent()
        }else{
            playerNode.removeFromParent()
        }
        self.run(SKAction.wait(forDuration: 2)){
            explosion?.removeFromParent()
            }
        health -= 1
    
    }
    
    let sensivity: CGFloat = 0.01
    
   override  func didSimulatePhysics() {
        if xAcceleration > sensivity || xAcceleration < sensivity * (-1)
        {
            self.acceleration = xAcceleration > 0 ? ((xAcceleration + sensivity) * 50) : ((xAcceleration - sensivity) * 50)
            player.position.x += self.acceleration
            rocketFire.position = CGPoint(x: player.position.x, y: player.position.y - player.frame.size.height / 2.2)
            if player.position.x+player.frame.width < self.frame.size.width/(-2) {
                player.position.x = self.frame.size.width/2
            } else if player.position.x > self.frame.size.width/2 + player.frame.size.width/2 {
                player.position.x = self.frame.size.width/(-2)-player.frame.width
            }
            reloadField.position = player.position
            reloadField.position.y += player.frame.size.height/2 + 10
        }
    }
    
    
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
       
    }
       
}

