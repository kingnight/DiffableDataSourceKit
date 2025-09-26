//
//  NewSongTableViewCell.swift
//  UITableViewDiffableDataSourceDemo
//
//  Created by kaijin on 2025/9/26.
//

import UIKit

class NewSongTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "NewSongTableViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with song: Song) {
        var content = self.defaultContentConfiguration()
        content.text = song.name
        content.secondaryText = song.artist
        content.image = UIImage(systemName: "music.mic")
        content.imageProperties.tintColor = .red
        self.contentConfiguration = content
    }
}