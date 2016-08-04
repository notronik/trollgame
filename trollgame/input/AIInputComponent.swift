//
//  AIInputComponent.swift
//  trollgame
//
//  Created by Nik on 04/08/2016.
//  Copyright © 2016 Niklas Vangerow. All rights reserved.
//

import Foundation

class AIInputComponent: EntityComponent {
    weak var entity: Entity!
    weak var target: Entity?
    var fixedGoal: Position?
    let usingFixedGoal: Bool
    
    init(target: Entity) {
        self.target = target
        self.usingFixedGoal = false
    }
    
    init(goal: Position) {
        self.fixedGoal = goal
        self.usingFixedGoal = true
    }
    
    func update(world: World) {
        if !usingFixedGoal {
            guard target != nil,
            entity.position != target!.position else { return }
        } else {
            guard fixedGoal != nil,
                entity.position != fixedGoal! else { return }
        }
        
        let path = self.astarPath(world: world, start: self.entity.position, goal: usingFixedGoal ? fixedGoal! : target!.position)
        if path.count > 0 {
            entity.newPosition = path[1]
        } else {
            entity.newPosition = entity.position + Direction.random().deltaPosition
        }
        
        guard let newPosition = entity.newPosition, let newDirection = Direction(delta: newPosition - entity.position) else {
            return
        }
        entity.direction = newDirection
    }
}

// MARK: A* -
// Based on this http://www.redblobgames.com/pathfinding/a-star/implementation.html
// TODO: Maybe quit early if path gets too long
extension AIInputComponent {
    struct ANode: Comparable {
        var cost: Double
        var position: Position
        
        init(position: Position, cost: Double) {
            self.position = position
            self.cost = cost
        }
    }
    
    func validNeighbors(world: World, node: Position) -> [Position] {
        var out = [Position]()
        
        func verifyAndAdd(_ direction: Direction) {
            let position = node + direction.deltaPosition
            
            // position has to be in world and can't be a wall
            guard world.inWorld(position) && world.tile(at: position) != .wallTile else { return }
            
            out.append(position)
        }
        
        verifyAndAdd(.up)
        verifyAndAdd(.down)
        verifyAndAdd(.left)
        verifyAndAdd(.right)
        
        return out
    }
    
    func heuristic(a: Position, b: Position) -> Double {
        let (x1, y1) = a.tuple
        let (x2, y2) = b.tuple
        
        let deltX = Double(abs(x1 - x2))
        let deltY = Double(abs(y1 - y2))
        
        return (deltX + deltY) * (1.0 + 10/1000.0) // manhattan distance heuristic + tiebreaking
    }
    
    func astar(world: World, start: Position, goal: Position) -> [Position: Position] {
        var frontier = PriorityQueue<ANode>(ascending: true, startingValues: [ANode(position: start, cost: 0)])
        
        var costSoFar = [Position: Double]()
        var cameFrom = [Position: Position]()
        
        cameFrom[start] = start
        costSoFar[start] = 0
        
        while !frontier.isEmpty {
            let current = frontier.pop()! // ! as not empty
            if current.position == goal {
                break
            }
            
            for next in validNeighbors(world: world, node: current.position) {
                let newCost = costSoFar[current.position]! + 10.0 // 10 is cost from current -> next. This is always 10 for now.
                if (costSoFar[next] == nil || newCost < costSoFar[next]!) {
                    costSoFar[next] = newCost
                    let priority = newCost  + heuristic(a: next, b: goal)
                    frontier.push(ANode(position: next, cost: priority))
                    cameFrom[next] = current.position
                }
            }
        }
        
        return cameFrom
    }
    
    func reconstructPath(start: Position, goal: Position, cameFrom: [Position: Position]) -> [Position] {
        var path = [Position]()
        var current = goal
        path.append(current)
        while current != start {
            if cameFrom[current] == nil {
               return []
            }
            current = cameFrom[current]!
            path.append(current)
        }
//        path.append(start) // starting position appended twice for some reason
        return path.reversed()
    }
    
    func astarPath(world: World, start: Position, goal: Position) -> [Position] {
        return reconstructPath(start: start, goal: goal, cameFrom: astar(world: world, start: start, goal: goal))
    }
}

// MARK: Comparable conformance for AIInputComponent.ANode -
func <(lhs: AIInputComponent.ANode, rhs: AIInputComponent.ANode) -> Bool {
    return lhs.cost < rhs.cost
}

func ==(lhs: AIInputComponent.ANode, rhs: AIInputComponent.ANode) -> Bool {
    return lhs.cost == rhs.cost
}
