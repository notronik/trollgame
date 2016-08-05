//
//  TrollAttackComponent.swift
//  trollgame
//
//  Created by Nik on 05/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

// MARK: AttackInformation -
/// Provides information about an attack. Used for notifications.
class AttackInformation: NSObject {
    let attacker: Entity
    let damage: Int
    
    init(attacker: Entity, damage: Int) {
        self.attacker = attacker
        self.damage = damage
    }
}

// MARK: AttackNotificationKeys -
/// Notification keys used for attacks
struct AttackNotificationKeys {
    static let attack = NSNotification.Name(rawValue: "NVEntityAttacked")
}

// MARK: AttackComponent -
/// Component used by entities that want to have attack capabilities.
class AttackComponent: EntityComponent {
    weak var entity: Entity!
    
    let attackable: Set<Tile>
    let strength: Int
    
    init(attackable: [TileProvider], strength: Int = 1) {
        self.attackable = Set<Tile>(attackable.map({ (provider) -> [Tile] in
            provider.containedTiles
        }).flatten())
        self.strength = strength
    }
    
    func update(world: World) {
        // Test if entity is there and attackable
        guard let attacking = world.entity(at: entity.position),
            attackable.contains(attacking.currentTile) else { return }
        
        attacking.notificationCenter.post(name: AttackNotificationKeys.attack, object: AttackInformation(attacker: entity, damage: strength))
    }
}

// MARK: AttackableComponent -
/// Component subclassed by entity-specific attack handlers.
class AttackableComponent: EntityComponent {
    final weak var entity: Entity!
    
    final var health: Int
    
    init(health: Int = 1) {
        self.health = health
    }
    
    final func entityBecameAvailable() {
        entity.notificationCenter.addObserver(self, selector: #selector(AttackableComponent.attacked(_:)), name: AttackNotificationKeys.attack, object: nil)
    }
    
    @objc final func attacked(_ notification: Notification) {
        guard let information = notification.object as? AttackInformation else { return }
        
        handleAttack(by: information.attacker, damage: information.damage)
    }
    
    func handleAttack(by attacker: Entity, damage: Int) {
        fatalError("Attack handling must be implemented by subclasses")
    }
}

class PlayerAttackableComponent: AttackableComponent {
    override func handleAttack(by attacker: Entity, damage: Int) {
        self.health -= damage
        guard self.health <= 0 else { return }
        
        NotificationCenter.default.post(name: .RendererDisplayMessage, object: RenderMessage(.negative, message: "You died."))
        NotificationCenter.default.post(name: .TerminateGameAfterInput, object: nil)
    }
}
