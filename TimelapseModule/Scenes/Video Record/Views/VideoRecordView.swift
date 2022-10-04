import UIKit

final class VideoRecordView: UIView {
    
    @objc
    var startOrStop: (() -> (), () -> ()) -> ()
    
    private lazy var startOrStopButton: UIButton = createStartOrStopButton(action: #selector(startOrStopTapped))
    lazy var previewView: UIView = createPreviewView()
    
    init(startOrStop: @escaping (() -> (), () -> ()) -> ()) {
        self.startOrStop = startOrStop
        super.init(frame: .zero)
        self.addViews()
        self.addConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addViews() {
        self.addSubview(previewView)
        self.addSubview(startOrStopButton)
    }
    
    private func addConstraints() {
        startOrStopButton.translatesAutoresizingMaskIntoConstraints = false
        previewView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            startOrStopButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            startOrStopButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            startOrStopButton.heightAnchor.constraint(equalToConstant: 70),
            startOrStopButton.widthAnchor.constraint(equalToConstant: 70),
            previewView.bottomAnchor.constraint(equalTo: bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewView.topAnchor.constraint(equalTo: topAnchor)
        ])
    }
    
    private func createPreviewView() -> UIView {
        let previewView = UIView()
        previewView.bounds = self.bounds
        return previewView
    }
    
    private func createStartOrStopButton(action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.configuration = buttonStopedConfiguration
        button.layer.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private var buttonPlayedConfiguration: UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.background.cornerRadius = 35
        config.cornerStyle = .capsule
        config.baseBackgroundColor = UIColor.clear
        config.baseForegroundColor = UIColor.red
        config.image = UIImage(systemName: "square.fill")?.resizableImage(withCapInsets: .init(top: 10, left: 10, bottom: 10, right: 10))
        return config
    }
    
    private var buttonStopedConfiguration: UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.background.cornerRadius = 35
        config.cornerStyle = .capsule
        config.baseBackgroundColor = UIColor.red
        config.baseForegroundColor = UIColor.red
        config.image = UIImage(systemName: "play.fill")
        return config
    }
    
    @objc
    private func startOrStopTapped() {
        startOrStop(
            {
                // handle finish
                startOrStopButton.configuration = buttonStopedConfiguration
            }, {
                // handle start
                startOrStopButton.configuration = buttonPlayedConfiguration
            })
    }
}
