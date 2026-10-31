import UIKit
import WebKit
import AVFoundation

/// Загружает HTML и другие ресурсы из Bundle приложения через локальную схему echo://.
/// Это позволяет WKWebView использовать постоянное хранилище сайта (localStorage/IndexedDB)
/// без подключения к серверу.
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              url.scheme?.lowercased() == "echo" else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        let components = url.pathComponents.filter { $0 != "/" }
        guard !components.isEmpty,
              !components.contains(".."),
              !components.contains(".") else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        let resourceName = components.last ?? "index.html"
        let resourceURL = URL(fileURLWithPath: resourceName)
        let ext = resourceURL.pathExtension
        let name = resourceURL.deletingPathExtension().lastPathComponent

        guard let fileURL = Bundle.main.url(
            forResource: name,
            withExtension: ext.isEmpty ? nil : ext
        ), let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let mimeType: String
        switch ext.lowercased() {
        case "html": mimeType = "text/html"
        case "css": mimeType = "text/css"
        case "js": mimeType = "text/javascript"
        case "json": mimeType = "application/json"
        case "png": mimeType = "image/png"
        case "jpg", "jpeg": mimeType = "image/jpeg"
        case "gif": mimeType = "image/gif"
        case "webp": mimeType = "image/webp"
        case "svg": mimeType = "image/svg+xml"
        case "mp3": mimeType = "audio/mpeg"
        case "m4a": mimeType = "audio/mp4"
        case "wav": mimeType = "audio/wav"
        case "mp4": mimeType = "video/mp4"
        default: mimeType = "application/octet-stream"
        }

        let response = URLResponse(
            url: url,
            mimeType: mimeType,
            expectedContentLength: data.count,
            textEncodingName: "utf-8"
        )

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

final class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    // Сильная ссылка на обработчик схемы на всё время жизни экрана.
    private let schemeHandler = LocalSchemeHandler()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var prefersStatusBarHidden: Bool { true }

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: "echo")

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.uiDelegate = self
        view.isOpaque = false
        view.backgroundColor = .black
        view.scrollView.backgroundColor = .black
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.scrollView.bounces = false
        view.allowsBackForwardNavigationGestures = false

        webView = view
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = URL(string: "echo://app/index.html") else { return }
        webView.load(URLRequest(url: url))
    }

    // Внешние ссылки открываются в Safari. Внутренние ресурсы echo:// остаются в приложении.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        } else if scheme == "echo" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }

    // Ссылки с target="_blank" также открываем во внешнем браузере.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url,
           ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(url)
        }
        return nil
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Режим playback нужен музыкальному плееру для фонового воспроизведения.
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            NSLog("Не удалось активировать аудиосессию: %@", error.localizedDescription)
        }

        let appWindow = UIWindow(frame: UIScreen.main.bounds)
        appWindow.rootViewController = ViewController()
        appWindow.backgroundColor = .black
        appWindow.makeKeyAndVisible()
        window = appWindow
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            NSLog("Не удалось восстановить аудиосессию: %@", error.localizedDescription)
        }
    }
}
