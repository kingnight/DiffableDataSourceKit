# UITableViewDiffableDataSource 完整指南

本文档详细介绍了如何使用 `UITableViewDiffableDataSource` 构建一个功能丰富的 iOS 列表应用。通过一个音乐播放列表的示例，我们将逐步探索从项目基本设置到实现复杂功能的完整过程。

## 1. 项目设置

为了更好地控制 UI 和视图层级，本项目完全以编程方式构建，未使用 Storyboard。

### 1.1. 移除 Storyboard 依赖

第一步是在项目中移除对 `Main.storyboard` 的依赖。这通过以下两个步骤完成：

1.  **修改 `Info.plist`**:
    删除了 `UISceneStoryboardFile` 键值对，以告知系统我们不再使用 Storyboard 来加载初始界面。

2.  **修改 `SceneDelegate.swift`**:
    在 `scene(_:willConnectTo:options:)` 方法中，我们以编程方式创建了 `UIWindow`，并将 `ViewController` 包装在一个 `UINavigationController` 中，然后将其设置为 `rootViewController`。

    ```swift
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    let window = UIWindow(windowScene: windowScene)
    let viewController = ViewController()
    let navigationController = UINavigationController(rootViewController: viewController)
    window.rootViewController = navigationController
    self.window = window
    window.makeKeyAndVisible()
    ```

### 1.2. 设置导航栏

通过将 `ViewController` 嵌入 `UINavigationController`，我们可以轻松地在 `ViewController` 中配置导航栏。在 `viewDidLoad()` 方法中，我们设置了标题和导航栏按钮：

```swift
title = "My Playlist"
let shuffleButton = UIBarButtonItem(title: "Shuffle", style: .plain, target: self, action: #selector(shuffleSongs))
navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSong))
navigationItem.leftBarButtonItems = [shuffleButton, editButtonItem]
```

## 2. 数据模型

清晰的数据模型是构建任何应用的基础。

-   **`Song`**: 一个遵循 `Hashable` 协议的结构体。我们添加了 `isFavorite` 属性来跟踪歌曲的收藏状态。特别地，我们重写了 `Hashable` 的实现，**仅基于歌曲的固有属性（`name`, `artist`, `image`）生成哈希值**。这确保了当 `isFavorite` 状态改变时，`DiffableDataSource` 仍然能将它识别为同一个对象实例，从而实现平滑的移动动画，而不是删除和插入。

    ```swift
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
    ```

-   **`Section`**: 一个遵循 `CaseIterable` 和 `Hashable` 的枚举，用于定义列表中的分区。

    ```swift
    enum Section: String, CaseIterable {
        case favorites = "Favorites"
        case disney = "Disney"
        case pop = "Pop"
    }
    ```

## 3. 使用 `UITableViewDiffableDataSource`

`UITableViewDiffableDataSource` 是现代 `UITableView` 开发的核心，它简化了数据更新和动画。

### 3.1. 创建 `dataSource`

在 `ViewController` 中，我们创建了一个 `dataSource` 实例。`cellProvider` 闭包现在变得更加复杂，它需要根据分区类型返回三种不同的单元格。

```swift
dataSource = ReorderableTableViewDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, song in
    guard let self = self, let section = self.dataSource.sectionIdentifier(for: indexPath.section) else {
        return UITableViewCell()
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
```

### 3.2. 使用 `snapshot` 更新 UI

所有对 `UITableView` 的数据更新都是通过创建和应用 `NSDiffableDataSourceSnapshot` 来完成的。这确保了 UI 和数据源始终保持同步，并自动处理了复杂的动画。

```swift
var snapshot = NSDiffableDataSourceSnapshot<Section, Song>()
snapshot.appendSections([.favorites, .disney, .pop])
snapshot.appendItems(songs, toSection: .disney)
snapshot.appendItems(popSongs, toSection: .pop)
dataSource.apply(snapshot, animatingDifferences: false)
```

## 4. 自定义单元格

为了展示不同的内容和样式，我们创建了三个自定义的 `UITableViewCell` 子类。

-   **`SongTableViewCell`**: 用于 "Favorites" 分区，展示歌曲的基本信息。
-   **`NewSongTableViewCell`**: 用于 "Pop" 分区，具有不同的图标和附件样式。
-   **`SwitchableSongTableViewCell`**: 用于 "Disney" 分区，它包含一个 `UISwitch` 开关。为了将开关的状态变化通知给 `ViewController`，我们定义了一个 `SwitchableSongTableViewCellDelegate` 协议。当开关状态改变时，单元格会调用代理方法，将自身和新的开关状态传递出去。

## 5. 核心与高级功能实现

### 5.1. 拖拽重排

为了实现拖拽重排，我们创建了一个 `UITableViewDiffableDataSource` 的子类 `ReorderableTableViewDataSource`，并重写了两个关键方法：

-   **`tableView(_:canMoveRowAt:)`**: 返回 `true` 以允许所有单元格移动。
-   **`tableView(_:moveRowAt:to:)`**: 在此方法中，我们更新了 `snapshot` 以反映新的项目顺序，然后重新应用它。这确保了即使在拖拽操作后，数据源和 UI 也能保持一致。

### 5.2. 滑动删除

通过实现 `UITableViewDelegate` 的 `tableView(_:trailingSwipeActionsConfigurationForRowAt:)` 方法，我们为每个单元格添加了一个删除操作。当用户滑动并点击删除时，我们从 `snapshot` 中移除对应的数据项，然后应用新的 `snapshot` 来更新 UI。

```swift
let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
    guard let self = self, let item = self.dataSource.itemIdentifier(for: indexPath) else {
        completion(false)
        return
    }
    var snapshot = self.dataSource.snapshot()
    snapshot.deleteItems([item])
    self.dataSource.apply(snapshot, animatingDifferences: true)
    completion(true)
}
```

### 5.3. 动态更新（添加和随机排序）

-   **添加歌曲**: `addSong()` 方法创建一个新的 `Song` 实例，将其添加到当前 `snapshot` 的 ".pop" 分区，然后应用 `snapshot` 以动画方式插入新行。
-   **随机排序**: `shuffleSongs()` 方法获取 "Disney" 分区的所有歌曲，将它们随机排序，然后更新 `snapshot` 以反映新的顺序。

### 5.4. 自定义分区与全局页眉

-   **分区页眉**: 为了显示分区的标题，我们实现了 `UITableViewDelegate` 的 `tableView(_:viewForHeaderInSection:)` 方法。在此方法中，我们出列一个可重用的 `UITableViewHeaderFooterView`，并使用 `defaultContentConfiguration()` 来设置其文本和样式。

-   **全局页眉**: 与分区页眉不同，我们还为整个 `UITableView` 添加了一个全局页眉。这通过在 `viewDidLoad()` 中设置 `tableView.tableHeaderView` 属性来实现。这个视图会随着列表滚动。

    ```swift
    let header = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 100))
    let label = UILabel(frame: header.bounds)
    label.text = "My Awesome Playlist"
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 24, weight: .bold)
    header.addSubview(label)
    tableView.tableHeaderView = header
    ```

### 5.5. 单元格驱动的数据更新：收藏夹功能

这是本项目最核心的交互功能，它演示了单元格内部的 UI 事件如何驱动整个数据源的变化。

1.  **遵循代理协议**: `ViewController` 遵循 `SwitchableSongTableViewCellDelegate` 协议。

2.  **实现代理方法**: `ViewController` 实现了 `didChangeSwitchValue(for:isOn:)` 方法。当 `SwitchableSongTableViewCell` 中的开关状态改变时，此方法被调用。

3.  **更新数据源**: 在代理方法中，我们执行以下操作：
    *   获取被操作的 `song` 对象。
    *   更新其 `isFavorite` 属性。
    *   从当前的 `snapshot` 中**删除**该 `song`。
    *   根据 `isOn` 的值，将该 `song` **添加**到 `.favorites` 或 `.disney` 分区。
    *   应用更新后的 `snapshot`，`DiffableDataSource` 会自动计算差异并以动画形式移动单元格。

    ```swift
    func didChangeSwitchValue(for cell: SwitchableSongTableViewCell, isOn: Bool) {
        guard let indexPath = tableView.indexPath(for: cell), var song = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        song.isFavorite = isOn
        
        var currentSnapshot = dataSource.snapshot()
        
        currentSnapshot.deleteItems([song])
        
        if isOn {
            currentSnapshot.appendItems([song], toSection: .favorites)
        } else {
            currentSnapshot.appendItems([song], toSection: .disney)
        }
        
        dataSource.apply(currentSnapshot, animatingDifferences: true)
    }
    ```

## 结论

通过结合 `UITableViewDiffableDataSource`、编程方式的 UI 构建、`UITableViewDelegate` 以及代理模式，我们创建了一个功能强大、交互丰富且易于维护的列表应用。这种现代的开发方式不仅简化了代码，还提供了流畅的用户体验和优雅的动画效果，完美地展示了如何构建复杂的、由用户交互驱动的 UI。