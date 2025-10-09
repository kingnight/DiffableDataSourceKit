// 自定义歌曲卡片单元格：展示封面、标题、动态副标题，并支持自动高度和闭包高度两种模式
// 功能说明：
// - 根据 Song 模型的现有字段（name、artist、image、isFavorite）动态拼接副标题内容，贴近真实业务：
//   · 当存在已知歌手的“简介”时，副标题会扩展为更丰富的文本（例如小段介绍/要点），以体现内容变更导致的高度变化
//   · 在自动高度模式下，通过 subtitleLabel 的多行文本触发行高自适应
//   · 在闭包高度模式下，通过 preferredHeight(for:) 根据内容（是否存在简介、是否收藏）返回不同的高度
// - 保持实现简单，不改动模型结构，不引入新的外部依赖

import UIKit

final class CustomSongCardCell: UITableViewCell {
    static let reuseIdentifier = "CustomSongCardCell"
    
    // Recommended default height when using closure-based heights
    static let defaultHeight: CGFloat = 96
    
    // 贴近真实业务：为常见歌手准备简短“简介”文本，用于动态拼接副标题
    // 注意：实际项目中这些可来自后端或本地化文案，这里仅演示用
    private static let artistBios: [String: String] = [
        "Idina Menzel": "Idina Menzel is known for her powerful vocals and Broadway performances, most notably in Wicked and Frozen.",
        "Peabo Bryson and Regina Belle": "A renowned duet celebrated for their timeless ballad 'A Whole New World' and evocative performances.",
        "Lea Salonga": "Lea Salonga is a Tony Award–winning artist famed for her roles in Miss Saigon and voice work for Disney.",
        "Ed Sheeran": "Ed Sheeran blends pop with folk influences, crafting heartfelt lyrics and chart-topping melodies.",
        "Mark Ronson ft. Bruno Mars": "Known for funk-inspired productions and energetic performances that spark modern retro hits."
    ]
    
    // Compute a preferred height based on content if needed（闭包模式高度估算）
    /// 根据是否存在简介、是否收藏返回不同高度，以体现内容变更会影响高度
    static func preferredHeight(for song: Song) -> CGFloat {
        // 有简介且是收藏：更高；有简介但非收藏：中等；否则默认
        let hasBio = artistBios[song.artist] != nil
        if hasBio && song.isFavorite { return 148 }
        if hasBio { return 120 }
        return defaultHeight
    }
    
    private let containerView = UIView()
    private let coverImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .systemGroupedBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        
        contentView.addSubview(containerView)
        containerView.addSubview(coverImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        
        let padding: CGFloat = 12
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),
            
            coverImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            coverImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
            coverImageView.widthAnchor.constraint(equalToConstant: 60),
            coverImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
        ])
        
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 8
    }
    
    /// 配置单元格：根据已有模型字段动态拼接副标题
    /// 规则：
    /// - 若存在 artist 简介：
    ///   · isFavorite=true 时：展示更丰富的多行内容（标题+要点/简介），触发自动高度
    ///   · isFavorite=false 时：展示简短介绍，限制为 2 行
    /// - 若不存在简介：保留原有行为（副标题为 artist，2 行）
    func configure(with song: Song) {
        titleLabel.text = song.name
        
        let bio = Self.artistBios[song.artist]
        if let bio = bio {
            if song.isFavorite {
                // 展示更丰富的多行内容，贴近真实“歌手介绍”或“歌曲描述”场景
                let richSubtitle = "\(song.artist)\n· \(bio)\n· This track resonates with fans worldwide.\n· Discover more behind the scenes and inspirations."
                subtitleLabel.text = richSubtitle
                subtitleLabel.numberOfLines = 0 // 允许多行
                print("[CustomSongCardCell] Configure rich subtitle for favorite: \(song.name) -> multi-line")
            } else {
                // 展示简短介绍（第一句），限制行数
                subtitleLabel.text = "\(song.artist) — \(bio)"
                subtitleLabel.numberOfLines = 2
                print("[CustomSongCardCell] Configure concise subtitle with bio: \(song.name) -> up to 2 lines")
            }
        } else {
            // 无简介，回退到基础副标题
            subtitleLabel.text = song.artist
            subtitleLabel.numberOfLines = 2
            print("[CustomSongCardCell] Configure basic subtitle: \(song.name) -> 2 lines")
        }
        
        if let image = UIImage(named: song.image) {
            coverImageView.image = image
        } else {
            coverImageView.image = UIImage(systemName: "music.note")
        }
    }
}