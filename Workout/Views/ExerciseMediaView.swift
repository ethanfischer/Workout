import SwiftUI
import ImageIO

struct ExerciseMediaView: View {
    let exercise: ExerciseDefinition
    var size: CGFloat = 120  // GIFs are 360x360, always square

    var body: some View {
        Group {
            switch exercise.mediaType {
            case .gif:
                if let url = exercise.mediaURL {
                    AnimatedGIFView(url: url)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            case .none:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "dumbbell.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
            }
        }
    }
}

// MARK: - Animated GIF View

struct AnimatedGIFView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        if let data = try? Data(contentsOf: url),
           let source = CGImageSourceCreateWithData(data as CFData, nil) {
            let frameCount = CGImageSourceGetCount(source)
            var images: [UIImage] = []
            var duration: Double = 0

            for i in 0..<frameCount {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: cgImage))
                    if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                       let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                        if let delayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double, delayTime > 0 {
                            duration += delayTime
                        } else if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                            duration += delayTime
                        } else {
                            duration += 0.1
                        }
                    }
                }
            }

            imageView.animationImages = images
            imageView.animationDuration = duration
            imageView.animationRepeatCount = 0
            imageView.startAnimating()
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    VStack(spacing: 20) {
        ExerciseMediaView(
            exercise: ExerciseDefinition(
                name: "Bench Press",
                type: .compound,
                category: .push,
                defaultSets: 4,
                defaultReps: "10"
            ),
            size: 160
        )
    }
}
