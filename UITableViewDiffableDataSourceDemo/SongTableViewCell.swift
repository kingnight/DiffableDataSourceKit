//
//  SongTableViewCell.swift
//  UITableViewDiffableDataSourceDemo
//
//  Created by kaijin on 2025/9/25.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    static let reuseIdentifier = "SongTableViewCell"

    let songImageView = UIImageView()
    let nameLabel = UILabel()
    let artistLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        songImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        artistLabel.font = .preferredFont(forTextStyle: .subheadline)
        artistLabel.textColor = .secondaryLabel

        let stackView = UIStackView(arrangedSubviews: [nameLabel, artistLabel])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(songImageView)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            songImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            songImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            songImageView.widthAnchor.constraint(equalToConstant: 50),
            songImageView.heightAnchor.constraint(equalToConstant: 50),

            stackView.leadingAnchor.constraint(equalTo: songImageView.trailingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with song: Song) {
        nameLabel.text = song.name
        artistLabel.text = song.artist
        if let image = UIImage(named: song.image) {
            songImageView.image = image
        } else {
            songImageView.image = UIImage(systemName: "music.note") // Placeholder
        }
    }
}