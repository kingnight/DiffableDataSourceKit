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
    
    // MARK: - Height Mode
    /// 控制行高模式：自动高度（Auto Layout）或闭包高度（固定/自定义逻辑）
    private enum HeightMode { case automatic, closure }
    private var heightMode: HeightMode = .automatic
    private lazy var heightModeControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Auto", "Closure"])
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(onHeightModeChanged(_:)), for: .valueChanged)
        return sc
    }()
    
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
        
        // 默认开启自动高度模式
        configureHeightMode(.automatic)
        
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
        
        // 在标题处加入高度模式切换
        navigationItem.titleView = heightModeControl
        
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
        // 新增完全自定义的卡片样式 cell
        tableView.register(CustomSongCardCell.self, forCellReuseIdentifier: CustomSongCardCell.reuseIdentifier)
        
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
                // 使用全新 CustomSongCardCell 演示高度控制
                let cell = tableView.dequeueReusableCell(withIdentifier: CustomSongCardCell.reuseIdentifier, for: indexPath) as! CustomSongCardCell
                cell.configure(with: song)
                return cell
            default:
                return UITableViewCell()
            }
        }
        
        // 创建适配器以简化快照操作
        adapter = DiffableTableAdapter(tableView: tableView, dataSource: dataSource, enableLogging: true)
    }
    
    // MARK: - Height Mode Configuration
    /// 配置高度模式，并设置对应的表格属性与闭包
    private func configureHeightMode(_ mode: HeightMode) {
        heightMode = mode
        switch mode {
        case .automatic:
            // 由 Auto Layout 计算高度（需要单元格有完整的垂直约束）
            adapter.enableAutomaticDimension(estimatedRowHeight: 80)
            adapter.setHeightProviders(height: nil, estimated: nil)
            if adapter.enableLogging { print("[ModernVC] Height mode -> automatic") }
        case .closure:
            // 使用闭包提供固定/动态高度（更可控）
            tableView.rowHeight = 60
            tableView.estimatedRowHeight = 60
            adapter.setHeightProviders(height: { [weak self] tableView, indexPath, song, section in
                guard let section = section else { return 60 }
                switch section {
                case .favorites:
                    // 对卡片 cell 使用自定义首选高度逻辑
                    return CustomSongCardCell.preferredHeight(for: song)
                case .disney:
                    return 60
                case .pop:
                    return 72
                default:
                    return 60
                }
            }, estimated: { tableView, indexPath, song, section in
                // 估算高度与实际高度保持一致或给出略小的值以提升性能
                guard let section = section else { return 60 }
                switch section {
                case .favorites:
                    return CustomSongCardCell.defaultHeight
                case .disney:
                    return 60
                case .pop:
                    return 72
                default:
                    return 60
                }
            })
            if adapter.enableLogging { print("[ModernVC] Height mode -> closure") }
        }
        // 刷新以应用高度变化
        tableView.reloadData()
    }
    
    /// SegmentedControl 切换事件
    @objc private func onHeightModeChanged(_ sender: UISegmentedControl) {
        let mode: HeightMode = sender.selectedSegmentIndex == 0 ? .automatic : .closure
        configureHeightMode(mode)
    }
    
    // MARK: - UITableViewDelegate (Height)
    /// 返回行高：根据当前高度模式选择 automaticDimension 或闭包提供的值
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch heightMode {
        case .automatic:
            return UITableView.automaticDimension
        case .closure:
            return adapter.heightForRow(at: indexPath) ?? tableView.rowHeight
        }
    }
    
    /// 返回预估行高：有助于提升滚动性能
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch heightMode {
        case .automatic:
            return tableView.estimatedRowHeight > 0 ? tableView.estimatedRowHeight : 80
        case .closure:
            return adapter.estimatedHeightForRow(at: indexPath) ?? tableView.estimatedRowHeight
        }
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