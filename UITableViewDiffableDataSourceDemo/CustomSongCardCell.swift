//
//  CustomSongCardCell.swift
//  UITableViewDiffableDataSourceDemo
//
//  Purpose: A fully custom UITableViewCell demonstrating explicit height control and
//  Auto Layout-friendly constraints (top/bottom) for automaticDimension.
//  This cell is used to showcase custom height via closures in DiffableTableAdapter,
//  and also works with UITableView.automaticDimension.
//

import UIKit

final class CustomSongCardCell: UITableViewCell {
    static let reuseIdentifier = "CustomSongCardCell"
    
    // Recommended default height when using closure-based heights
    static let defaultHeight: CGFloat = 96
    
    // Compute a preferred height based on content if needed (simplified here)
    static func preferredHeight(for song: Song) -> CGFloat {
        // You can tune this logic based on text length, image presence, etc.
        // For demo purpose, return a fixed value.
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
    
    /// Setup UI with full vertical constraints to support automaticDimension
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.backgroundColor = UIColor.secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        
        contentView.addSubview(containerView)
        containerView.addSubview(coverImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        
        let padding: CGFloat = 12
        NSLayoutConstraint.activate([
            // Container pinned to contentView top/bottom to support automaticDimension
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
    
    /// Configure data
    func configure(with song: Song) {
        titleLabel.text = song.name
        subtitleLabel.text = song.artist
        if let image = UIImage(named: song.image) {
            coverImageView.image = image
        } else {
            coverImageView.image = UIImage(systemName: "music.note")
        }
    }
}