//
//  MTLMatrix.swift
//  Pods
//
//  Created by Mohssen Fathi on 8/25/16.
//
//

import UIKit

/*
    A work in progress...
 */

public
struct MTLMatrix {

    private var matrix: [Any]!
    
    init(shape: [Int]) {
        matrix = randomMatrix(with: shape)
    }

    func randomMatrix(with shape: [Int]) -> [Any] {
        
        if shape.count == 0 { return [] }
        if shape.count == 1 {
            let size = shape[0]
            if size == 1 {
                return [Float(arc4random()) / Float(UINT32_MAX)]
            }
            return (0 ..< size).map { _ in Float(arc4random()) / Float(UINT32_MAX) }
        }
        
        var matrix = [Any]()
        
        for i in 0 ..< shape[0] {
            matrix.append( randomMatrix(with: Array(shape[1 ..< shape.count])) )
        }
        
        return matrix
    }
    
    subscript(index: Int) -> Any {
        return matrix[index]
    }
}
