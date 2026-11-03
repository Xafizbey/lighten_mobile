import AVFoundation
import SwiftUI

/// The lesson's material: text, video link, audio, presentation.
struct MaterialSection: View {
    let lesson: StudentLessonDTO

    var body: some View {
        let hasAny = lesson.body != nil || lesson.videoUrl != nil || lesson.audioUrl != nil
            || !lesson.slides.isEmpty
        if hasAny {
            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.Lesson.material).font(Typo.card)
                if let video = lesson.videoUrl, let url = URL(string: video) {
                    // YouTube unlisted (CLAUDE.md): open in the YouTube app or Safari.
                    Link(destination: url) {
                        Label(Strings.Lesson.openVideo, systemImage: "play.rectangle")
                    }
                    .buttonStyle(.secondary)
                }
                if let audio = lesson.audioUrl, let url = URL(string: audio) {
                    AudioPlayerView(url: url)
                }
                if !lesson.slides.isEmpty {
                    SlideDeck(slides: lesson.slides)
                }
                if let body = lesson.body, !body.isEmpty {
                    Card { MaterialText(body) }
                }
            }
        }
    }
}

/// Play and pause, with how far it has gone. The audio streams from the CDN.
struct AudioPlayerView: View {
    let url: URL
    /// Asked before every play from the start. False: do not play (exam limit).
    var beforePlay: (() async -> Bool)?
    var disabled = false

    @StateObject private var player = AudioPlayer()

    var body: some View {
        HStack(spacing: 14) {
            Button {
                Task {
                    if player.isPlaying {
                        player.pause()
                    } else {
                        if player.progress == 0, let beforePlay, !(await beforePlay()) { return }
                        player.play(url)
                    }
                }
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(Palette.onBright)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(disabled ? Palette.line : Palette.yellow))
            }
            .disabled(disabled && !player.isPlaying)
            .accessibilityLabel(player.isPlaying ? Strings.Lesson.pause : Strings.Lesson.listen)

            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Lesson.audio).font(Typo.bodyBold)
                ProgressView(value: player.progress).tint(Palette.greenText)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.bg))
        .overlay(RoundedRectangle(cornerRadius: Metrics.radius).strokeBorder(Palette.line, lineWidth: 2))
        .onDisappear { player.pause() }
    }
}

@MainActor
final class AudioPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0

    nonisolated(unsafe) private var player: AVPlayer?
    nonisolated(unsafe) private var observer: Any?
    nonisolated(unsafe) private var endObserver: NSObjectProtocol?

    func play(_ url: URL) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        if player == nil {
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            observer = player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main
            ) { [weak self] time in
                Task { @MainActor in self?.tick(time) }
            }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.finished() }
            }
            self.player = player
        }
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    private func tick(_ time: CMTime) {
        guard let duration = player?.currentItem?.duration.seconds, duration.isFinite, duration > 0
        else { return }
        progress = min(1, time.seconds / duration)
    }

    private func finished() {
        isPlaying = false
        progress = 0
        player?.seek(to: .zero)
    }

    deinit {
        if let observer { player?.removeTimeObserver(observer) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }
}

/// A Grammar presentation: page images, swiped one by one.
struct SlideDeck: View {
    let slides: [SlideDTO]
    @State private var index = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Lesson.slides).font(Typo.bodyBold)
            TabView(selection: $index) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { i, slide in
                    AsyncImage(url: AppConfig.fileURL(slide.fileId)) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .aspectRatio(aspect, contentMode: .fit)
            .background(RoundedRectangle(cornerRadius: Metrics.radius).fill(Palette.bg))
            .clipShape(RoundedRectangle(cornerRadius: Metrics.radius))
            Text(fill(Strings.Lesson.slideOf, ["n": index + 1, "total": slides.count]))
                .font(Typo.caption)
                .foregroundStyle(Palette.inkSoft)
        }
    }

    private var aspect: CGFloat {
        guard let first = slides.first, first.height > 0 else { return 4 / 3 }
        return first.width / first.height
    }
}
