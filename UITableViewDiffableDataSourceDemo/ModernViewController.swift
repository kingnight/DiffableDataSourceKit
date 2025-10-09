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
        let demosButton = UIBarButtonItem(title: "Heights", style: .plain, target: self, action: #selector(presentHeightDemos))
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSong)), demosButton]
        navigationItem.leftBarButtonItems = [editButtonItem]
        
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
    
    // MARK: - Height Change Demos
    /// 展示四种高度更新场景的菜单
    @objc private func presentHeightDemos() {
        let ac = UIAlertController(title: "Height Update Demos", message: "选择一种场景进行演示", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "自动高度：内容变更触发高度变化", style: .default, handler: { _ in
            self.demoAutomaticHeightContentChange()
        }))
        ac.addAction(UIAlertAction(title: "闭包高度：内容变更导致闭包高度不同", style: .default, handler: { _ in
            self.demoClosureHeightChange()
        }))
        ac.addAction(UIAlertAction(title: "身份变更：删除旧项+追加新项", style: .default, handler: { _ in
            self.demoIdentityChange()
        }))
        ac.addAction(UIAlertAction(title: "仅内容变更：reconfigure（高度不变）", style: .default, handler: { _ in
            self.demoReconfigureNoHeightChange()
        }))
        ac.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(ac, animated: true)
    }
    
    /// 场景1：自动高度模式下，内容变更导致高度变化（例如 favorites 卡片 subtitle 变长）
    /// 示例中需要两次操作才能更新高度，详见注释
    private func demoAutomaticHeightContentChange() {
        guard heightMode == .automatic else {
            let alert = UIAlertController(title: "请切换到自动高度模式", message: "当前为闭包高度模式，AutomaticDimension 更适合该演示。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }
        var snap = adapter.dataSource.snapshot()
        let favorites = snap.itemIdentifiers(inSection: .favorites)
        if favorites.isEmpty {
            // 若没有收藏，则从 Disney 拿第一首并加入到 favorites，同时设置 isFavorite=true
            if let first = snap.itemIdentifiers(inSection: .disney).first {
                var updated = first
                updated.isFavorite = true
                snap.deleteItems([first])
                snap.appendItems([updated], toSection: .favorites)
                //在自动高度模式里，插入/移动行时，UITableView会先用“预估高度”做动画，通常不会在同一次批处理里再做一次自动布局的二次测量以避免高度“跳变”。因此你在“删除旧 + 追加新”（跨分区移动）后，新建的 Favorites 区 cell会以 estimatedRowHeight 的值完成插入动画，很多情况下不会立即反映更长的多行文本带来的真实高度。这个时候页面看起来就像“只移动了分区，没变高度”。
                if adapter.enableLogging { print("[Demo] Automatic: moved one item to favorites with isFavorite=true; now reload to ensure height recalculation") }
                adapter.dataSource.apply(snap, animatingDifferences: true)

                let alert = UIAlertController(title: "已更新内容以触发自动高度", message: "已将 Disney 的第一首歌曲移至 Favorites 并丰富其副标题，行高已在本次操作中变化。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好的", style: .default))
                present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: "无可演示的歌曲", message: "请先添加或移动歌曲到 Favorites。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                present(alert, animated: true)
            }
            return
        }
        // 取第一项，使其 isFavorite=true，以便 CustomSongCardCell 展示更丰富的内容（多行）
        var item = favorites[0]
        item.isFavorite = true
        
        // 根据文档最佳实践，当身份不变时，使用 reload 来更新内容并触发高度重新计算
        if adapter.enableLogging { print("[Demo] Automatic: reloading item to trigger height recalculation.") }
        //此处调用reload才会更新高度
        adapter.reload([item])

        let alert = UIAlertController(title: "已更新内容以触发自动高度", message: "Favorites 中第一项内容已加长，Auto Layout 自动计算行高。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }
    
    /// 场景2：闭包高度模式下，内容变更导致高度变化
    private func demoClosureHeightChange() {
        guard heightMode == .closure else {
            let alert = UIAlertController(title: "请切换到闭包高度模式", message: "当前为自动高度模式，闭包高度更适合该演示。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }
        var snap = adapter.dataSource.snapshot()
        let favorites = snap.itemIdentifiers(inSection: .favorites)
        if favorites.isEmpty {
            // 若没有收藏，则从 Pop 拿第一首加入到 favorites
            if let first = snap.itemIdentifiers(inSection: .pop).first {
                var updated = first
                updated.isFavorite = true
                snap.deleteItems([first])
                snap.appendItems([updated], toSection: .favorites)
                adapter.dataSource.apply(snap, animatingDifferences: true)
                if adapter.enableLogging { print("[Demo] Closure: moved one item to favorites with isFavorite=true") }
            } else {
                let alert = UIAlertController(title: "无可演示的歌曲", message: "请先添加或移动歌曲到 Favorites。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                present(alert, animated: true)
            }
            return
        }
        // 切换 isFavorite 以影响 CustomSongCardCell.preferredHeight(for:)
        var item = favorites[0]
        item.isFavorite.toggle()
        //Song 是一个 struct 且实现了 Hashable；根据项目文档，身份（哈希等同性）由 name/artist/image 决定，isFavorite 不参与身份。此时仅改变 isFavorite 并不需要“删除旧 + 追加新”，直接 reload 即可让闭包高度重新计算。
        // 使用 reload 使闭包高度重新计算
        adapter.reload(item, animatingDifferences: true)
        let alert = UIAlertController(title: "已更新内容以触发闭包高度", message: "根据 isFavorite 的变化，preferredHeight 返回了不同的高度。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }
    
    /// 场景3：身份变更（修改 name 等），需删除旧项并追加新项到同一分区
    private func demoIdentityChange() {
        var snap = adapter.dataSource.snapshot()
        let disney = snap.itemIdentifiers(inSection: .disney)
        guard let target = disney.first else {
            let alert = UIAlertController(title: "无可演示的歌曲", message: "Disney 分区为空。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }
        var updated = target
        updated.name = target.name + " (v2)"
        snap.deleteItems([target])
        snap.appendItems([updated], toSection: .disney)
        adapter.dataSource.apply(snap, animatingDifferences: true)
        if adapter.enableLogging { print("[Demo] Identity change: replaced item with new name -> triggers new cell & height recompute if needed") }
        let alert = UIAlertController(title: "已进行身份变更", message: "通过删除旧项并追加新项的方式替换了 Disney 中第一首歌。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }
    
    /// 场景4：仅内容变更但高度与类型不变，使用 reconfigure 提高性能
    private func demoReconfigureNoHeightChange() {
        // 选取 Pop 分区第一项，修改非身份字段（isFavorite），并使用 reconfigure
        let snap = adapter.dataSource.snapshot()
        let pop = snap.itemIdentifiers(inSection: .pop)
        guard var target = pop.first else {
            let alert = UIAlertController(title: "无可演示的歌曲", message: "Pop 分区为空。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }
        // 仅更新不会影响身份的字段，保证高度与类型不变
        target.isFavorite.toggle()
        // 直接使用 reconfigure：保留现有 cell 实例，仅更新内容（不改变高度/类型）
        adapter.reconfigure(target, animatingDifferences: true)
        if adapter.enableLogging { print("[Demo] Reconfigure: updated content without changing height/type for Pop item") }
        let alert = UIAlertController(title: "已进行内容更新（reconfigure）", message: "Pop 第一项仅更新内容，不改变高度和类型。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
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
