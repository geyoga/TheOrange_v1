//
//  GameScene.swift
//  TheOrange_v1
//
//  Created by Georgius Yoga Dewantama on 16/05/19.
//  Copyright © 2019 Georgius Yoga Dewantama. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // make object for player
    let player = SKSpriteNode(imageNamed: "SpaceShip")

    let bulletSound = SKAction.playSoundFileNamed("laserSound.mp3", waitForCompletion: false)
    
    
    
    var gameArea : CGRect
    
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
        
        let background = SKSpriteNode(imageNamed: "BlueBackground")
        background.size = self.size
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        background.zPosition = 0
        self.addChild(background)
        
        
        player.setScale(1.5)
        player.position = CGPoint(x: self.size.width/2, y: self.size.height * 0.2)
        player.zPosition = 2
        self.addChild(player)
    }
    
    
    func fireBullet () {
        let bullet = SKSpriteNode(imageNamed: "Bullet")
        bullet.setScale(1.5)
        bullet.position = player.position
        bullet.zPosition = 1
        self.addChild(bullet)
        
        let moveBullet = SKAction.moveTo(y: self.size.height + bullet.size.height, duration: 1)
        let deleteBullet = SKAction.removeFromParent()
        let bulletSequence = SKAction.sequence([bulletSound, moveBullet, deleteBullet])
        bullet.run(bulletSequence)
        
    }
    
    func spawnEnemy()  {
        <#function body#>
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        fireBullet()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches {
            
            let pointOfTouch = touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            
            let amountDraggedX = pointOfTouch.x - previousPointOfTouch.x
            
            player.position.x += amountDraggedX
            
            if player.position.x > gameArea.maxX - player.size.width {
                player.position.x = gameArea.maxX - player.size.width
            }
            else if player.position.x < gameArea.minX + player.size.width {
                player.position.x = gameArea.minX + player.size.width
            }
        }
    }
    
}
