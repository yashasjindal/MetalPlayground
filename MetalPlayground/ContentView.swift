import SwiftUI

struct ContentView: View {
    var body: some View {
        MetalView()
            .frame(minWidth: 600, minHeight: 400).aspectRatio(3/2, contentMode: .fit)
    }
}

#Preview {
    ContentView()
}
