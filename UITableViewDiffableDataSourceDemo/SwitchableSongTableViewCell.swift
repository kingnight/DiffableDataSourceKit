import UIKit

protocol SwitchableSongTableViewCellDelegate: AnyObject {
    func didChangeSwitchValue(for cell: SwitchableSongTableViewCell, isOn: Bool)
}

class SwitchableSongTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SwitchableSongTableViewCell"
    weak var delegate: SwitchableSongTableViewCellDelegate?
    
    private let songSwitch = UISwitch()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupSwitch()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSwitch() {
        accessoryView = songSwitch
        songSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    }
    
    func configure(with song: Song) {
        var content = defaultContentConfiguration()
        content.text = song.name
        content.secondaryText = song.artist
        content.image = UIImage(systemName: song.image)
        contentConfiguration = content
        
        songSwitch.isOn = song.isFavorite
    }
    
    @objc private func switchValueChanged() {
        delegate?.didChangeSwitchValue(for: self, isOn: songSwitch.isOn)
    }
}