//
//  ModernViewController.swift
//  UITableViewDiffableDataSourceDemo
//
//  Created on 2025/10/5.
//
// 使用 DiffableDataSourceKit 实现的现代化表格视图控制器
// 展示了如何使用 BaseReorderableDiffableDataSource 和 DiffableTableAdapter 简化代码

#if canImport(UIKit)
import UIKit
#endif

class ModernViewController: UIViewController, UITableViewDelegate {
    
    // MARK: - UI Components
    let tableView = UITableView(frame: .zero, style: .grouped)
    
    // MARK: - Data
    // 复用与 ViewController 相同的 Section 和 Song 模型
    let disneySongs = [
        Song(name: "Let It Go", artist: "Idina Menzel", image: "letitgo"),
        Song(name: "A Whole New World", artist: "Peabo Bryson and Regina Belle", image: "wholenewworld"),
        Song(name: "Reflection", artist: "Lea Salonga", image: "reflection")
    ]
    
    let popSongs = [
        Song(name: "Shape of You", artist: "Ed Sheeran", image: "shapeofyou"),
        Song(name: "Uptown Funk", artist: "Mark Ronson ft. Bruno Mars", image: "uptownfunk")
    ]
    
    // MARK: - DiffableDataSourceKit Components
    var dataSource: BaseReorderableDiffableDataSource<Section, Song>!
    var adapter: DiffableTableAdapter<Section, Song>!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureDataSource()
        setupInitialData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // 设置导航栏
        title = "Modern Playlist"
        let shuffleButton = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(shuffleSongs))
        let reloadButton = UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(reloadRandomSong))
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSong)), reloadButton]
        navigationItem.leftBarButtonItems = [shuffleButton, editButtonItem]
        
        // 设置表格视图
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tableView.delegate = self
        
        // 注册单元格和头部视图
        tableView.register(SongTableViewCell.self, forCellReuseIdentifier: SongTableViewCell.reuseIdentifier)
        tableView.register(NewSongTableViewCell.self, forCellReuseIdentifier: NewSongTableViewCell.reuseIdentifier)
        tableView.register(SwitchableSongTableViewCell.self, forCellReuseIdentifier: SwitchableSongTableViewCell.reuseIdentifier)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
        
        // 设置表格头部视图
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 100))
        let label = UILabel(frame: header.bounds)
        label.text = "Modern Awesome Playlist"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        header.addSubview(label)
        tableView.tableHeaderView = header
    }
    
    // MARK: - DataSource Configuration
    private func configureDataSource() {
        // 使用 BaseReorderableDiffableDataSource 的工厂方法创建数据源
        dataSource = BaseReorderableDiffableDataSource.create(
            tableView: tableView,
            allowCrossSectionMove: false,
            allowReordering: true,
            enableLogging: true
        ) { [weak self] tableView, indexPath, song, section in
            guard let self = self else { return UITableViewCell() }
            
            // 根据不同的 section 返回不同类型的单元格
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
            default:
                return UITableViewCell()
            }
        }
        
        // 创建适配器以简化快照操作
        adapter = DiffableTableAdapter(tableView: tableView, dataSource: dataSource, enableLogging: true)
    }
    
    // MARK: - Initial Data Setup
    private func setupInitialData() {
        // 使用适配器的便捷方法设置初始数据
        adapter.applyInitialSnapshot(
            sections: [.favorites, .disney, .pop],
            itemsBySection: [
                .disney: disneySongs,
                .pop: popSongs,
                .favorites: []
            ],
            animatingDifferences: false
        )
    }
    
    // MARK: - Actions
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    @objc private func addSong() {
        let newSong = Song(name: "New Modern Song", artist: "Modern Artist", image: "newSong")
        // 使用适配器的便捷方法添加新歌曲
        adapter.append(newSong, to: .pop, animatingDifferences: true)
    }
    
    @objc private func shuffleSongs() {
        // 使用适配器的便捷方法随机排序歌曲
        adapter.shuffle(section: .disney, animatingDifferences: true)
    }
    
    /// 重新加载随机歌曲 - 演示reload方法的使用场景
    /// 当单元格需要完全重新创建（例如高度变化）时，应使用reload而非reconfigure
    @objc private func reloadRandomSong() {
        // 获取当前快照中的所有歌曲
        let snapshot = adapter.dataSource.snapshot()
        let allSongs = snapshot.itemIdentifiers
        
        guard !allSongs.isEmpty else { return }
        
        // 随机选择一首歌曲
        if let randomSong = allSongs.randomElement() {
            // 1. 修改歌曲名称，添加标记以便在UI中识别
            var updatedSong = randomSong
            updatedSong.name = randomSong.name + " (Updated)"
            
            // 2. 先删除原始歌曲，然后添加更新后的歌曲
            var newSnapshot = adapter.dataSource.snapshot()
            newSnapshot.deleteItems([randomSong])
            newSnapshot.appendItems([updatedSong], toSection: .disney)
            adapter.dataSource.apply(newSnapshot, animatingDifferences: true)
            
            // 显示提示信息
            let alert = UIAlertController(
                title: "已重新加载歌曲",
                message: "使用reload方法重新加载了'\(updatedSong.name)'。\n\n与reconfigure不同，reload会创建全新的单元格，适用于需要改变单元格高度或类型的情况。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
        
        // 使用适配器的便捷方法获取 section 标识符
        guard let sectionIdentifier = adapter.sectionIdentifier(at: section) else {
            return headerView
        }
        
        var content = headerView?.defaultContentConfiguration()
        content?.text = sectionIdentifier.rawValue
        content?.textProperties.font = .boldSystemFont(ofSize: 18)
        headerView?.contentConfiguration = content
        return headerView
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 获取要删除的项目
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return UISwipeActionsConfiguration()
        }
        
        // 创建删除操作
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self = self else { return }
            // 使用适配器的便捷方法删除歌曲
            self.adapter.delete(item, animatingDifferences: true)
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - SwitchableSongTableViewCellDelegate
extension ModernViewController: SwitchableSongTableViewCellDelegate {
    func didChangeSwitchValue(for cell: SwitchableSongTableViewCell, isOn: Bool) {
        guard let indexPath = tableView.indexPath(for: cell), let song = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        // 使用适配器的便捷方法移动歌曲到不同的 section
        if isOn {
            adapter.move(song, to: .favorites, animatingDifferences: true)
        } else {
            adapter.move(song, to: .disney, animatingDifferences: true)
        }
    }
}