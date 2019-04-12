//
//  MetalBuffer.swift
//  ScheduleChart
//
//  Created by Alexander Graschenkov on 12/04/2019.
//  Copyright © 2019 Alex the Best. All rights reserved.
//

import UIKit
import MetalKit

class MetalBuffer: NSObject {

    init(device: MTLDevice) {
        self.device = device
        super.init()
    }
    
    var indices : [IndexType] = []
    var vertices: PageAlignedContiguousArray<vector_float2>!
    var colors: PageAlignedContiguousArray<vector_float4>!
    
    var triangleIndicesBuffer : MTLBuffer!
    var triangleStripIndicesBuffer : MTLBuffer!
    var vertexBuffer : MTLBuffer!
    var colorsBuffer : MTLBuffer!
    
    func setup(maxDataCount: Int, maxItemsCount: Int, triangleStrip: Bool) {
        if vertexBuffer == nil || allocatedVerticesCount < maxDataCount*maxItemsCount {
            allocatedVerticesCount = maxDataCount*maxItemsCount
            vertices = PageAlignedContiguousArray(repeating: vector_float2(0, 0), count: allocatedVerticesCount)
            vertexBuffer = device.makeBufferWithPageAlignedArray(vertices)
        }
        
        if colorsBuffer == nil || allocatedColorsCount < maxDataCount {
            allocatedColorsCount = maxDataCount
            colors = PageAlignedContiguousArray(repeating: vector_float4(0, 0, 0, 0), count: allocatedColorsCount)
            colorsBuffer = device.makeBufferWithPageAlignedArray(colors)
        }
        
        if triangleStrip {
            let count = maxDataCount * maxItemsCount
            if triangleStripIndicesBuffer == nil || allocatedTriangleStripIndexes < count {
                allocatedTriangleStripIndexes = count
                let indices = generateTriangelStripIndices(count: count)
                triangleStripIndicesBuffer = (device.makeBuffer(bytes: indices, length: MemoryLayout<IndexType>.stride * indices.count, options: .storageModeShared))
            }
        } else {
            let count = maxDataCount * maxItemsCount
            if triangleIndicesBuffer == nil || allocatedTriangleIndexes < count {
                allocatedTriangleIndexes = count
                let indices = generateTriangelIndices(count: count)
                triangleIndicesBuffer = (device.makeBuffer(bytes: indices, length: MemoryLayout<IndexType>.stride * indices.count, options: .storageModeShared))
            }
        }
    }
    
    // private
    private var allocatedVerticesCount = 0
    private var allocatedColorsCount = 0
    private var allocatedTriangleIndexes = 0
    private var allocatedTriangleStripIndexes = 0
    private var device: MTLDevice
    
    private func generateTriangelStripIndices(count: Int) -> [IndexType] {
        return Array(0..<IndexType(count * 4))
    }
    
    private func generateTriangelIndices(count: Int) -> [IndexType] {
        var result: [IndexType] = []
        result.reserveCapacity(count * 6)
        for i in  0..<count {
            let offset = IndexType(i*4)
            result.append(contentsOf: [offset, offset + 1, offset + 2,
                                       offset + 1, offset + 2, offset + 3])
        }
        return result
    }
}
