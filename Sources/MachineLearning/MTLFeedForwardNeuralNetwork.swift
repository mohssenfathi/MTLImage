//
//  MTLFeedForwardNeuralNetwork.swift
//  Pods
//
//  Created by Mohssen Fathi on 8/25/16.
//
//

import UIKit
import Accelerate
import MTLImage

public
class MTLFeedForwardNeuralNetwork: NSObject {

    var numberOfLayers: Int!
    var sizes: [Int]!
    var biases = [[[Float]]]()
    var weights = [[[Float]]]()
    
    public init(_ sizes: [Int]) {
        super.init()
        
        self.numberOfLayers = sizes.count
        self.sizes = sizes

        initialize()
        
        let trainingData: [(data: [Float], label: [Float])] = [
            ( [0, 100], [0, 1] ),
            ( [100, 30], [1, 0] ),
            ( [10, 150], [0, 1] ),
            ( [200, 10], [1, 0] ),
            ( [20, 750], [0, 1] ),
        ]

        let testData: [[Float]] = [
            [20, 300],
            [200, 20],
            [2000, 10],
            [345, 5],
            [1700, 0],
        ]
        
        stochasticGradientDescent(trainingData: trainingData, testData: testData, epochs: 1, miniBatchSize: 1, learningRate: 3.0)
    }
    
    
    // MARK: - Initialization
    
    func initialize() {

        weights = createWeights(defaultValue: nil)
        biases = createBiases(defaultValue: nil)
        
        feedForward([2, 4])
    }

    func createWeights(defaultValue: Float?) -> [[[Float]]] {
        
        var mat = [[[Float]]]()
        for i in 1 ..< sizes.count {
            
            var set = [[Float]]()
            for j in 0 ..< sizes[i] {
                set.append((0 ..< sizes[i - 1]).map { _ in defaultValue ?? (Float(arc4random()) / Float(UINT32_MAX)) })
            }
            mat.append(set)
        }
        
        return mat
    }
    
    func createBiases(defaultValue: Float?) -> [[[Float]]] {
        
        var mat = [[[Float]]]()
        for i in 1 ..< sizes.count {
            var set = [[Float]]()
            for j in 0 ..< sizes[i] {
                set.append([ defaultValue ?? (Float(arc4random()) / Float(UINT32_MAX))])
            }
            mat.append(set)
        }
        
        return mat
    }
    
    
    // MARK: - Neural Net Operations
    
    func feedForward(_ input: [Float]) -> [Float] {
        
        var out: [Float]! = nil
        var newOut: [Float]!
        var i: Int = 0
        
        for (weightArray, biasArray) in zip(weights, biases) {
         
            if out == nil { out = input }
            newOut = [Float](repeating: 0.0, count: weightArray.count)
            i = 0
            
            for (weight, bias) in zip(weightArray, biasArray) {

                var a = [Float](repeating: 0.0, count: 1)
                vDSP_mmul(weight, 1, out, 1, &a, 1, 1, 1, 1)
                newOut[i] = (sigmoid(a.first!) + bias.first!)
                i += 1
                
            }
            
            out = newOut
            
        }
        
        return out
    }
    
    func stochasticGradientDescent(trainingData: [(data: [Float], label: [Float])], testData: [[Float]],
                                   epochs: Int, miniBatchSize: Int, learningRate: Float) {
        
        let n = trainingData.count
        
        for i in 0 ..< epochs {
            updateMiniBatch(trainingData.choose(miniBatchSize), learningRate: learningRate)
        }
        
    }
    
    func updateMiniBatch(_ miniBatch: [(data: [Float], label: [Float])], learningRate: Float) {
        
        var nb = createBiases(defaultValue: 0.0)
        var nw = createWeights(defaultValue: 0.0)
        
        for (data, label) in miniBatch {
            var (dnb, dnw) = backprop(data: data, label: label)
            
//            nb += dnb
//            nw += dnw
        }
        
        //            for (index, element) in dnb.enumerated() {
        //                nb[index] += element
        //            }
        
        
        //            nb = nb + dnb for nb, dnb in zip(nabla_b, delta_nabla_b)]
        //            nw = [nw+dnw for nw, dnw in zip(nabla_w, delta_nabla_w)]
    }
    
    func backprop(data: [Float], label: [Float]) -> ([Float], [Float]) {
        
        var nb = createBiases(defaultValue: 0.0)
        var nw = createWeights(defaultValue: 0.0)
        
        // feedforward
        var activation = data
        var activations = [data]
        var zs = [[Float]]()
        
        for (weightArray, biasArray) in zip(weights, biases) {
            
            for (weight, bias) in zip(weightArray, biasArray) {
                
                var z = [Float](repeating: 0.0, count: 1)
                vDSP_mmul(weight, 1, activation, 1, &z, 1, 1, 1, 1)
                zs.append(z + bias)
                
                activation = [sigmoid(z.first!)]
                activations.append(activation)
            }
        }
        
        return ([], [])
    }
    
    // MARK: - Activation Functions
    
    func sigmoid(_ value: Float) -> Float {
        return 1.0 / (1.0 + exp(-value))
    }
    
    
    
    // MARK: - Helpers
    
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
    
    
    
}



extension Array {

    var shuffled: Array {
        var elements = self
        return elements.shuffle()
    }

    @discardableResult
    mutating func shuffle() -> Array {
        
        indices.dropLast().forEach { a in
            guard case let b = Int(arc4random_uniform(UInt32(count - a))) + a, b != a else { return }
            swap(&self[a], &self[b])
        }
        return self
    }
    
    var chooseOne: Element {
        return self[Int(arc4random_uniform(UInt32(count)))]
    }
    
    func choose(_ n: Int) -> Array {
        return Array(shuffled.prefix(n))
    }
}


infix operator • { associativity left }

func • (left: [Float], right: [Float]) -> Float {
    return zip(left, right).map(*).reduce(0, +)
}

func + (left: [Float], right: [Float]) -> [Float] {
    return zip(left, right).map(+)
}

func += (left: inout [Float], right: [Float]) -> [Float] {
    return zip(left, right).map(+)
}

