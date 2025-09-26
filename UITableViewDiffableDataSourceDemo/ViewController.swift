//
//  ViewController.swift
//  UITableViewDiffableDataSourceDemo
//
//  Created by kaijin on 2025/9/25.
//

import UIKit

// 定義 Section 的類型，並遵從 CaseIterable 以便遍歷
enum Section: String, CaseIterable {
    case favorites = "Favorites"
    case disney = "Disney"
    case pop = "Pop"
}

// 定義歌曲的資料結構，並遵從 Hashable
struct Song: Hashable {
    let name: String
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

class ReorderableTableViewDataSource: UITableViewDiffableDataSource<Section, Song> {

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        print("canMoveRowAt called for indexPath: \(indexPath)")
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("moveRowAt called from \(sourceIndexPath) to \(destinationIndexPath)")
        // Prevent moving between sections
        guard sourceIndexPath.section == destinationIndexPath.section else {
            print("Move between sections prevented.")
            self.apply(self.snapshot(), animatingDifferences: false)
            return
        }
        
        guard let sourceIdentifier = itemIdentifier(for: sourceIndexPath) else { return }
        
        var snapshot = self.snapshot()
        let section = snapshot.sectionIdentifiers[sourceIndexPath.section]
        var items = snapshot.itemIdentifiers(inSection: section)
        
        // Reorder the items in the array
        let movedItem = items.remove(at: sourceIndexPath.row)
        items.insert(movedItem, at: destinationIndexPath.row)
        
        // Update the snapshot for this section
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: section))
        snapshot.appendItems(items, toSection:section)
        
        print("Applying new snapshot for reorder.")
        apply(snapshot, animatingDifferences: false)
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

class ViewController: UIViewController, UITableViewDelegate {

    // 建立一個 UITableView
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    // 歌曲資料陣列
    let songs = [
        Song(name: "Let It Go", artist: "Idina Menzel", image: "letitgo"),
        Song(name: "A Whole New World", artist: "Peabo Bryson and Regina Belle", image: "wholenewworld"),
        Song(name: "Reflection", artist: "Lea Salonga", image: "reflection")
    ]
    
    let popSongs = [
        Song(name: "Shape of You", artist: "Ed Sheeran", image: "shapeofyou"),
        Song(name: "Uptown Funk", artist: "Mark Ronson ft. Bruno Mars", image: "uptownfunk")
    ]
    
    // 建立一個 UITableViewDiffableDataSource
    var dataSource: ReorderableTableViewDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定 navigation bar
        title = "My Playlist"
        let shuffleButton = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(shuffleSongs))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSong))
        navigationItem.leftBarButtonItems = [shuffleButton, editButtonItem]

        // 將 tableView 加入 view 中
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tableView.delegate = self
        
        // 註冊 cell 和 header
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.reuseIdentifier)
        tableView.register(NewSongTableViewCell.self, forCellReuseIdentifier: NewSongTableViewCell.reuseIdentifier)
        tableView.register(SwitchableSongTableViewCell.self, forCellReuseIdentifier: SwitchableSongTableViewCell.reuseIdentifier)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
        
        // 设置 TableView 的 Header
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 100))
        let label = UILabel(frame: header.bounds)
        label.text = "My Awesome Playlist"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        header.addSubview(label)
        tableView.tableHeaderView = header

        configureDataSource()
        applyInitialSnapshot()
    }
    
    func configureDataSource() {
        // 建立 dataSource
        dataSource = ReorderableTableViewDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, song in
            guard let self = self else { return UITableViewCell() }
            
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else {
                // Fallback to a default cell if section is not found
                return tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.reuseIdentifier, for: indexPath)
            }

            switch section {
            case .disney:
                let cell = tableView.dequeueReusableCell(withIdentifier: SwitchableSongTableViewCell.reuseIdentifier, for: indexPath) as! SwitchableSongTableViewCell
                cell.configure(with: song)
                cell.delegate = self
                return cell
            case .pop:
                let cell = tableView.dequeueReusableCell(withIdentifier: NewSongTableViewCell.reuseIdentifier, for: indexPath) as! NewSongTableViewCell
                cell.configure(with: song)
                return cell
            case .favorites:
                let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.reuseIdentifier, for: indexPath) as! SongTableViewCell
                cell.configure(with: song)
                return cell
            }
        })
    }
    
    func applyInitialSnapshot() {
        // 建立 snapshot
        var snapshot = NSDiffableDataSourceSnapshot<Section, Song>()
        // 加入 section
        snapshot.appendSections([.favorites, .disney, .pop])
        // 加入 item
        snapshot.appendItems(songs, toSection: .disney)
        snapshot.appendItems(popSongs, toSection: .pop)
        // 套用 snapshot
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    @objc private func addSong() {
        let newSong = Song(name: "New Song", artist: "New Artist", image: "newSong")
        var snapshot = dataSource.snapshot()
        snapshot.appendItems([newSong], toSection: .pop)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc private func shuffleSongs() {
        var snapshot = dataSource.snapshot()
        let disneySongs = snapshot.itemIdentifiers(inSection: .disney)
        snapshot.deleteItems(disneySongs)
        snapshot.appendItems(disneySongs.shuffled(), toSection: .disney)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
        let section = dataSource.snapshot().sectionIdentifiers[section]
        var content = headerView?.defaultContentConfiguration()
        content?.text = section.rawValue
        content?.textProperties.font = .boldSystemFont(ofSize: 18)
        headerView?.contentConfiguration = content
        return headerView
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Get the item to delete
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return UISwipeActionsConfiguration()
        }
        
        // Create a delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            var snapshot = self.dataSource.snapshot()
            snapshot.deleteItems([item])
            self.dataSource.apply(snapshot, animatingDifferences: true)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}


// MARK: - SwitchableSongTableViewCellDelegate
extension ViewController: SwitchableSongTableViewCellDelegate {
    func didChangeSwitchValue(for cell: SwitchableSongTableViewCell, isOn: Bool) {
        guard let indexPath = tableView.indexPath(for: cell), var song = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        song.isFavorite = isOn
        
        var currentSnapshot = dataSource.snapshot()
        
        // Delete the item from its old location
        currentSnapshot.deleteItems([song])
        
        // Append it to its new location
        if isOn {
            currentSnapshot.appendItems([song], toSection: .favorites)
        } else {
            currentSnapshot.appendItems([song], toSection: .disney)
        }
        
        // Reconfigure the item to force the cell to be re-created using the cell provider.
        // This ensures the correct cell type (with/without the switch) is used for the new section.
        
        dataSource.apply(currentSnapshot, animatingDifferences: true)
    }
}

