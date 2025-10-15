//
//  Model.swift
//  UITableViewDiffableDataSourceDemo
//
//  Created by pioneer on 2025/10/15.
//


// 定義 Section 的類型，並遵從 CaseIterable 以便遍歷
enum Section: String, CaseIterable {
    case favorites = "Favorites"
    case disney = "Disney"
    case pop = "Pop"
}

// 定義歌曲的資料結構，並遵從 Hashable
struct Song: Hashable {
    var name: String
    let artist: String
    let image: String
    var isFavorite: Bool = false
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(artist)
        hasher.combine(image)
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.name == rhs.name && lhs.artist == rhs.artist && lhs.image == rhs.image
    }
}
