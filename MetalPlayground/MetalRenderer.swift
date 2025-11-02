import SwiftUI
import MetalKit

// MARK: - Vertex data for a triangle
private let triangleVertices: [Float] = [
    // position.xyz,          color.rgb
     0.0,   0.4330127, 0.0,   1.0, 0.0, 0.0, // top - red
    -0.5,  -0.4330127, 0.0,   0.0, 1.0, 0.0, // left - green
     0.5,  -0.4330127, 0.0,   0.0, 0.0, 1.0  // right - blue
]

// MARK: - Metal Renderer
final class MetalRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var vertexBuffer: MTLBuffer!

    init(mtkView: MTKView) {
        super.init()
        device = mtkView.device
        commandQueue = device.makeCommandQueue()
        commandQueue?.label = "Main Command Queue"
        vertexBuffer = device.makeBuffer(bytes: triangleVertices,
                                         length: MemoryLayout<Float>.size * triangleVertices.count,
                                         options: [])

        let library = device.makeDefaultLibrary()!
        let vertexFunc = library.makeFunction(name: "vertex_main")
        let fragmentFunc = library.makeFunction(name: "fragment_main")

        // Explicit vertex layout for position (attr 0) and color (attr 1)
        let vertexDescriptor = MTLVertexDescriptor()
        // Position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // Color
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 3
        vertexDescriptor.attributes[1].bufferIndex = 0
        // Layout
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 6
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1

        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunc
        pipelineDesc.fragmentFunction = fragmentFunc
        pipelineDesc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDesc.vertexDescriptor = vertexDescriptor
        pipelineDesc.label = "Basic Triangle Pipeline"
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor
        else { return }

        descriptor.colorAttachments[0].loadAction = .clear

        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "Frame Command Buffer"
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.label = "Main Render Encoder"
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

// MARK: - SwiftUI bridge
struct MetalView: NSViewRepresentable {
    final class Coordinator {
        var renderer: MetalRenderer?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 1)
        mtkView.framebufferOnly = true
        mtkView.preferredFramesPerSecond = 60

        // Hold a strong reference to the renderer via the Coordinator so the weak delegate doesn't deallocate it
        let renderer = MetalRenderer(mtkView: mtkView)
        context.coordinator.renderer = renderer
        mtkView.delegate = renderer
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}
