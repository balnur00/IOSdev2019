//
//  GameScene.swift
//  killer
//
//  Created by Zhanna Amanbayeva on 11/12/19.
//  Copyright © 2019 Zhanna Amanbayeva. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var levelNumber = 0
    var gameScore = 0
    let scoreLabel = SKLabelNode(fontNamed: "the bold font")
    
    var gameIsPaused = false
    
    var livesNumber = 3
    let livesLabel = SKLabelNode(fontNamed: "the bold font")
    
    let player = SKSpriteNode(imageNamed: "kazah")
    
    let bulletSound = SKAction.playSoundFileNamed("bulletSound.mp3", waitForCompletion: false)
    
    enum gameState{
        case preGame //before start
        case inGame  //during game
        case afterGame  //end
    }
    var currentGameState = gameState.inGame
    
    struct PhysicsCategories{
        static let None : UInt32 = 0
        static let Player : UInt32 = 0b1 //1
        static let Bullet : UInt32 = 0b10 //2
        static let Enemy : UInt32 = 0b100 //4
    }
    
    func random() -> CGFloat {
        return(CGFloat(arc4random()) / 0xFFFFFFFF)
    }
    func random(min min: CGFloat, max: CGFloat) -> CGFloat{
        return random() * (max - min) + min
    }
    var gameArea : CGRect
   
    
    
    override init(size: CGSize) {
       
        
        let maxAspectRatio: CGFloat = 16.0/9.0
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
        
        let background = SKSpriteNode(imageNamed: "background-wings")
        background.size = self.size
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        background.zPosition = 0
        self.addChild(background)
        
    
        player.setScale(0.13)
        player.position = CGPoint(x: self.size.width/2, y: self.size.height/7)
        player.zPosition = 2
//        player.name = "Player"
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player
        player.physicsBody!.collisionBitMask = PhysicsCategories.None
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(player)
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 70
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.position = CGPoint(x: self.size.width*0.35, y: self.size.height*0.9)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
        
        livesLabel.text = "Lives: 3"
        livesLabel.fontSize = 60
        livesLabel.fontColor = SKColor.white
        livesLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        livesLabel.position = CGPoint(x: self.size.width*0.65, y: self.size.height*0.9)
        livesLabel.zPosition = 100
               self.addChild(livesLabel)
        
        startNewLevel()
    }
    //LIFE
    func looseALife(){
        livesNumber -= 1
        livesLabel.text = "Lives: \(livesNumber)"
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1, duration: 0.2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        livesLabel.run(scaleSequence)
        
        if livesNumber == 0{
            runGameOver()
        }
        
    }
    //SCORE
    func addScore(){
        gameScore += 1
        scoreLabel.text = "Score: \(gameScore)"
        
        if gameScore == 5 || gameScore == 10 || gameScore == 15{
              startNewLevel()
        }
    }
      //GAMEOVER
    func runGameOver(){
        
        currentGameState = gameState.afterGame
        self.removeAllActions()
        self.enumerateChildNodes(withName: "Bullet") { bullet, stop in
            bullet.removeAllActions()
        }
        self.enumerateChildNodes(withName: "Enemy") { enemy, stop in
                   enemy.removeAllActions()
               }
        
//        self.enumerateChildNodes(withName: "Player") { player, stop in
//                   player.removeAllActions()
//               }
    }
    
    func runPauseGame(){
        if gameIsPaused{
            gameIsPaused = false
        }
        else{
            gameIsPaused = true
        }
        if gameIsPaused {
            let levelDuration = 100.0
            let spawn = SKAction.run(spawnEnemy)
            let waitToSpawn = SKAction.wait(forDuration: levelDuration)
            let spawnSequence = SKAction.sequence([ waitToSpawn, spawn])
            let spawnForever = SKAction.repeatForever(spawnSequence)
            self.run(spawnForever, withKey: "spawningEnemies")
        }
    }
    
    //CONTACT between B1 and B2
    func didBegin(_ contact: SKPhysicsContact) {
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            body1 = contact.bodyA
            body2 = contact.bodyB
        } else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Enemy{   //if player hit enemy
            if body1.node != nil{
                spawnExplosion(spawnPosition: body1.node!.position)
                
            }
            if body2.node != nil{
                spawnExplosion(spawnPosition: body2.node!.position)
            }
            
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            
            runGameOver()
        }
        if body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.Enemy && (body2.node?.position.y)! < self.size.height {   //if kill enemy
            addScore()
            
            if body2.node != nil{
                 spawnExplosion(spawnPosition: body2.node!.position)
            }
           
                   body1.node?.removeFromParent()
                   body2.node?.removeFromParent()
                   
               }
    }
    //BOOOOM
    func spawnExplosion(spawnPosition: CGPoint){
        let explosion = SKSpriteNode(imageNamed: "kazy")
        explosion.position = spawnPosition
        explosion.zPosition = 3
        explosion.setScale(0)
        self.addChild(explosion)
        
        let scaleIn = SKAction.scale(to: 1, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        let explosionSequence = SKAction.sequence([scaleIn, fadeOut, delete])
        explosion.run(explosionSequence)
    }
    
    //SPEEED
    func startNewLevel(){
        levelNumber += 1
        
        if self.action(forKey: "spawningEnemies") != nil{
            self.removeAction(forKey: "spawningEnemies")
        }
        var levelDuration = NSTimeIntervalSince1970
        switch levelNumber {
        case 1: levelDuration = 1.5
        case 2: levelDuration = 1.2
        case 3: levelDuration = 1
        case 4: levelDuration = 0.8
        default:
            levelDuration = 0.5
            print("Cannot Find Level Info")
            
        }
        
        let spawn = SKAction.run(spawnEnemy)
        let waitToSpawn = SKAction.wait(forDuration: levelDuration)
        let spawnSequence = SKAction.sequence([ waitToSpawn, spawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        self.run(spawnForever, withKey: "spawningEnemies")
    }
    
    //BULLEET
    
    func fireBullet(){
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.setScale(0.25)
//        bullet.position = CGPoint(x: self.size.width/2, y: self.size.height/5)
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.name = "Bullet"
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = PhysicsCategories.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(bullet)
        
        let moveBullet = SKAction.moveTo(y:self.size.height + bullet.size.height, duration: 1)
        let deleteBullet = SKAction.removeFromParent()
        let bulletSequence = SKAction.sequence([bulletSound, moveBullet, deleteBullet])
        bullet.run(bulletSequence)
    }
    //HORSES
    func spawnEnemy(){
        let randomXStart = random(min: gameArea.minX, max: gameArea.maxX)
        let randomXEnd = random(min: gameArea.minX, max: gameArea.maxX)
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)
        let endPoind = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)
        
        let enemy = SKSpriteNode(imageNamed: "horse")
        enemy.setScale(0.4)
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.name = "Enemy"
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Enemy
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endPoind, duration: 3.0)
        let deleteEnemy = SKAction.removeFromParent()
        let looseALifeAction = SKAction.run(looseALife)
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy, looseALifeAction])
        
        
        if currentGameState == gameState.inGame{
        enemy.run(enemySequence)
        }
        let dx = endPoind.x - startPoint.x
        let dy = endPoind.y - startPoint.y
        let amountToRotate = atan2(dy, dx)
        enemy.zRotation = amountToRotate
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameIsPaused{
        if currentGameState == gameState.inGame{
            fireBullet()
            }
        }
//        spawnEnemy()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameIsPaused{
        for touch: AnyObject in touches{
            let pointOfTouch =  touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            
            let amountDragged = pointOfTouch.x - previousPointOfTouch.x
            
            if currentGameState == gameState.inGame{
                
                player.position.x += amountDragged
                
            }
           
            if player.position.x > gameArea.maxX{
                player.position.x = gameArea.maxX
                
            }
            if player.position.x < gameArea.minX{
                player.position.x = gameArea.minX
                
            }
        }
        }
    }
   
    }
     
    
//    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.green
//            self.addChild(n)
//        }
//    }
//
//    func touchMoved(toPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.blue
//            self.addChild(n)
//        }
//    }
//
//    func touchUp(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.red
//            self.addChild(n)
//        }
//    }
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
//
//        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
//    }
//
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
//    }
//
//
//    override func update(_ currentTime: TimeInterval) {
//        // Called before each frame is rendered
//    }
//}
