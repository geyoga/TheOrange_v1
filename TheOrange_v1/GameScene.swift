//
//  GameScene.swift
//  TheOrange_v1
//
//  Created by Georgius Yoga Dewantama on 16/05/19.
//  Copyright © 2019 Georgius Yoga Dewantama. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

@available(iOS 10.0, *)
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // variable player score
    var gameScore = 0
    let scoreLabel = SKLabelNode(fontNamed: "SF Pro Display Light")
    
    var levelNumber = 0
    var livesNumber = 1
    
    let impact = UIImpactFeedbackGenerator()
    
    // variable for accelerometer purpose
    var motionManager = CMMotionManager()
    var destX : CGFloat = 0.0
    
    // make object for player
    let player = SKSpriteNode(imageNamed: "SpaceShip")
    
    // Source code of Sound Effect
    let bulletSound = SKAction.playSoundFileNamed("laserSound.mp3", waitForCompletion: false)
    let enemySound = SKAction.playSoundFileNamed("bubbleSound.wav", waitForCompletion: false)
    
    // some conditions for stop and start the game
    enum gameState {
        case preGame
        case inGame
        case afterGame
    }
    
    // condition current game
    var currentGameState = gameState.inGame
    
    // address for physic Body.
    /* memberikan alamat pada setiap object, digunakan ketika 2 object bertemu
     */
    struct PhysicsCategories {
        static let None : UInt32 = 0
        static let Player : UInt32 = 0b1
        static let Bullet : UInt32 = 0b10
        static let Enemy : UInt32 = 0b100
    }
    
    // randon number generator from 0 to 2^32
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    // overloading random function to assign minimum and maximum of range numbers
    func random(min : CGFloat, max : CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    // variable for area constraint
    var gameArea : CGRect
    
    // make rectangle constraint for game area with aspect ratio
    override init(size: CGSize) {
        let maxAspectRatio : CGFloat = 16.0 / 9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth) / 2
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        
        
        self.physicsWorld.contactDelegate = self
        
        // show the blue background and bubble foreground
        let background = SKSpriteNode(imageNamed: "BlueBackground")
        let foreground = SKSpriteNode(imageNamed: "bubble")
        background.size = self.size
        foreground.size.width = 400
        foreground.setScale(2.5)
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        foreground.position = CGPoint(x: frame.size.width/2, y: frame.size.height - 100)
        background.zPosition = 0
        foreground.zPosition = 3
        self.addChild(background)
        self.addChild(foreground)
        
       
        // build the space ship
        player.setScale(1.5)
        player.position = CGPoint(x: self.size.width/2, y: self.size.height * 0.1) // 0.2
        player.zPosition = 2
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player
        player.physicsBody!.collisionBitMask = PhysicsCategories.None
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(player)
        
        // read the accelerometer sensor
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.01
            motionManager.startAccelerometerUpdates(to: .main){
                (data, error) in
                guard let data = data, error == nil else {
                    return
                }
                let currentX = self.player.position.x
                self.destX = currentX + CGFloat(data.acceleration.x * 500) //1000
            }
            
        }
        // show the score label
        scoreLabel.text = "0"
        scoreLabel.fontSize = 200
        scoreLabel.fontColor = SKColor.init(white: 0.8, alpha: 0.1)
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        scoreLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        scoreLabel.zPosition = 1
        self.addChild(scoreLabel)

        startNewLevel()
        
        // make circle indicator
        
        
    }
    // if you want to change the spaceship lives, so when enemy arrived at the end point the spaceship
    // not game over directly
    func loseALife() {
         livesNumber -= 1
        
        if livesNumber == 0 {
            runGameOver()
        }
    }
    
    func runGameOver()  {
        
        currentGameState = gameState.afterGame
        
        // make the entire game stop but the bullet and enemy want stop
        self.removeAllActions()
        
        // make the bullet stop moving with reference name, because func bullet declare in local
        self.enumerateChildNodes(withName: "Bullet") { (bullet, stop) in
            bullet.removeAllActions()
        }
        // make the enemy bullet stop moving with reference name, because func enemy delace in local
        self.enumerateChildNodes(withName: "Enemy") { (enemy, stop) in
            enemy.removeAllActions()
        }
        // show the alert notification
        alertGameOver()
    }
    // when the game is over, user will click alert and start new game
    func startNewGame()  {
        
        let sceneMoveTo = GameScene(size: self.size)
        sceneMoveTo.scaleMode = self.scaleMode
        let myTransition = SKTransition.fade(withDuration: 0.5)
        self.view!.presentScene(sceneMoveTo, transition: myTransition)
        
        
    }
    // show the alert, consist of game over title and user score
    func alertGameOver() {
    
        let alert = UIAlertController(title: "Game Over", message: "Score : \(gameScore)", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Again", style: .default, handler: {
            action in self.startNewGame()
        }
        ))
        
        self.view?.window?.rootViewController?.present(alert, animated: true, completion: nil)

    }
    
    // when user hit the enemy the score will increase
    func addScore()  {
        gameScore += 1
        scoreLabel.text = "\(gameScore)"
        
        // when score reach some amount, user will going to next level
        if gameScore == 10 || gameScore == 25 || gameScore == 50 || gameScore == 75 {
            startNewLevel()
        }
    }
    
        // make a contact body
    func didBegin(_ contact: SKPhysicsContact) {
        
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.contactTestBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        }
        else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Enemy{
            // if the player has hit the enemy
            if body1.node != nil {
            spawnExplosion(spawnPosition: body1.node!.position)
            }
            if body2.node != nil {
            spawnExplosion(spawnPosition: body2.node!.position)
            }
            impact.impactOccurred()
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            
            runGameOver()
        }
        if body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.Enemy {
            // if the bullet has hit the enemy
            addScore()
            
            if body2.node != nil{
                if body2.node!.position.y > self.size.height{
                    return
                }
                else{
                    spawnExplosion(spawnPosition: body2.node!.position)
                }
            }
            impact.impactOccurred()
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
        }
    }
    
    func spawnExplosion(spawnPosition : CGPoint)  {
        
        // show the explosion on location that they contact
        let explosion = SKSpriteNode (imageNamed: "Explosion")
        explosion.position = spawnPosition
        explosion.zPosition = 3
        explosion.setScale(0)
        self.addChild(explosion)
        
        // the timeline of explosion - scale, fadeout, delete
        let scaleIn = SKAction.scale(to: 1.5, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        let explosionSequence = SKAction.sequence([enemySound, scaleIn, fadeOut, delete])
        explosion.run(explosionSequence)
        
    }
    
    func startNewLevel()  {
        
        levelNumber += 1
        
        if self.action(forKey: "SpawnEnemy") != nil {
            self.removeAction(forKey: "SpawnEnemy")
        }
        // levelDuration of enemy Spawn
        var levelDuration = TimeInterval()
        switch levelNumber {
        case 1 : levelDuration = 2 // 1.2
        case 2 : levelDuration = 1.2   // 1
        case 3 : levelDuration = 0.8 // 0.8
        case 4 : levelDuration = 0.6 // 0.6
        default:
            levelDuration = 0.6
        }
        // repeat the enemy life (wait for duration, spawn)
        let spawn = SKAction.run(spawnEnemy)
        let waitToSpawn = SKAction.wait(forDuration: levelDuration)
        let spawnSequence = SKAction.sequence([waitToSpawn, spawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        self.run(spawnForever, withKey: "SpawnEnemy")
    }
    
    
    func fireBullet() {
        // make a bullet object
        let bullet = SKSpriteNode(imageNamed: "Bullet")
        bullet.name = "Bullet" // for reference stop moving
        bullet.setScale(1.5)
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = PhysicsCategories.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(bullet)
        
        // the timeline of bullet
        let moveBullet = SKAction.moveTo(y: self.size.height + bullet.size.height, duration: 1)
        let deleteBullet = SKAction.removeFromParent()
        let bulletSequence = SKAction.sequence([bulletSound, moveBullet, deleteBullet])
        bullet.run(bulletSequence)
        
    }
    
    func spawnEnemy()  {
        
        // make a random point on start and stop
        let randomXStart = random(min: gameArea.minX, max: gameArea.maxX)
        let randomXEnd = random(min: gameArea.minX * 1.3, max: gameArea.maxX * 0.7) // resize the random end
        
        // random point assign to CGPoint
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)
        let endPoint = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)
        
        // make an enemy object
        let enemy = SKSpriteNode(imageNamed: "OvalMed1")
        enemy.name = "Enemy"
        enemy.setScale(1.8)
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Enemy
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet
        self.addChild(enemy)
        
        // timeline of enemy - move from top to bottom. if not shooted the user game over
        let moveEnemy = SKAction.move(to: endPoint, duration: 3)
        let deleteEnemy = SKAction.removeFromParent()
        let loseAlifeAction = SKAction.run(loseALife)
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy, loseAlifeAction])
        
        if currentGameState == gameState.inGame{
            enemy.run(enemySequence)
        }
        
    }
 
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // fire the bullet every user touch the screen
        if currentGameState == gameState.inGame {
            fireBullet()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // when you want move the spaceship with touches
        /*
        for touch: AnyObject in touches {
            
            let pointOfTouch = touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            
            let amountDraggedX = pointOfTouch.x - previousPointOfTouch.x
            
            if currentGameState == gameState.inGame {
                player.position.x += amountDraggedX
            }

            if player.position.x > gameArea.maxX - player.size.width {
                player.position.x = gameArea.maxX - player.size.width
            }
            else if player.position.x < gameArea.minX + player.size.width {
                player.position.x = gameArea.minX + player.size.width
            }
        }
         */
    }
    override func update(_ currentTime: TimeInterval) {
        
        // update the position of spaceship with accelerometer
        
        if currentGameState == gameState.inGame {
            // constraint the space ship movement on game area
            if destX > gameArea.maxX - player.size.width {
                destX = gameArea.maxX - player.size.width
            }
            
            else if destX < gameArea.minX + player.size.width {
                destX = gameArea.minX + player.size.width
            }
            
            // take action of the player
            let action = SKAction.moveTo(x: destX, duration: 0.1)
            player.run(action)
        }
        
    }
}
