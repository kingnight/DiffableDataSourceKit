# DiffableDataSourceKit 使用指南

`DiffableDataSourceKit` 是一个轻量级的工具集，旨在简化 `UITableViewDiffableDataSource` 的使用。它通过提供一个可重用的、支持泛型的数据源子类和一个便捷的适配器，帮助开发者减少模板代码，更专注于业务逻辑。

本文档将结合 `ModernViewController.swift` 中的示例，介绍如何使用 `DiffableDataSourceKit` 的核心组件。

## 核心组件

1.  **`BaseReorderableDiffableDataSource<Section, Item>`**: 一个可重排的、支持分区的 `UITableViewDiffableDataSource` 子类。
2.  **`DiffableTableAdapter<Section, Item>`**: 一个适配器，封装了常见的 `NSDiffableDataSourceSnapshot` 操作，简化数据更新。

---

## 1. `BaseReorderableDiffableDataSource`

这是数据源的核心。它通过一个静态工厂方法 `create` 来初始化，该方法允许你传入一个“分区感知”的 `cellBuilder` 闭包，从而轻松地为不同分区返回不同类型的 `UITableViewCell`。

### 创建数据源

在 `ModernViewController.swift` 中，我们这样创建数据源：

```swift
// ModernViewController.swift

private func configureDataSource() {
    // 使用 BaseReorderableDiffableDataSource 的工厂方法创建数据源
    dataSource = BaseReorderableDiffableDataSource.create(
        tableView: tableView,
        allowCrossSectionMove: false, // 禁止跨区移动
        allowReordering: true,        // 允许重排
        enableLogging: true           // 开启日志
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
            let cell = tableView.dequeueReusableCell(withIdentifier: CustomSongCardCell.reuseIdentifier, for: indexPath) as! CustomSongCardCell
            cell.configure(with: song)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    // ...
}
```

**关键点**:

*   **`create` 工厂方法**: 避免了在初始化闭包中捕获 `self` 的复杂性。
*   **`cellBuilder` 闭包**: 提供了四个参数 `(UITableView, IndexPath, Item, Section?)`。`Section?` 参数是 `DiffableDataSourceKit` 的核心优势，它让你能够直接访问当前 `indexPath` 所属的分区标识符，从而实现类型安全的 `switch` 逻辑。
*   **配置**:
    *   `allowReordering`: 控制用户是否能拖动重排 cell。
    *   `allowCrossSectionMove`: 如果允许重排，此项控制是否能将 cell 从一个分区拖到另一个分区。
    *   `enableLogging`: 在控制台打印快照应用和重排的详细日志，便于调试。

---

## 2. `DiffableTableAdapter`

`DiffableTableAdapter` 是一个辅助类，它让快照（Snapshot）操作变得极其简单。你不再需要手动创建和配置 `NSDiffableDataSourceSnapshot`，只需调用适配器提供的便捷方法即可。

### 初始化适配器

创建完 `dataSource` 后，立即用它和 `tableView` 来初始化 `adapter`。

```swift
// ModernViewController.swift

// ...
// 创建适配器以简化快照操作
adapter = DiffableTableAdapter(tableView: tableView, dataSource: dataSource, enableLogging: true)
// ...
```

### 数据操作

`adapter` 提供了多种方法来修改 `tableView` 的数据。

#### a. 设置初始数据

使用 `applyInitialSnapshot` 来加载第一屏数据。

```swift
// ModernViewController.swift

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
```

#### b. 增、删、改数据

`adapter` 封装了 `append`, `delete`, `move` 等常用操作。

```swift
// ModernViewController.swift

@objc private func addSong() {
    let newSong = Song(name: "New Modern Song", artist: "Modern Artist", image: "newSong")
    // 使用适配器的便捷方法添加新歌曲
    adapter.append(newSong, to: .pop, animatingDifferences: true)
}

// 移动一个 item 到另一个 section
// adapter.move(song, to: .favorites)

// 删除一个 item
// adapter.delete(song)
```

#### c. 更新数据 (`reload` vs `reconfigure`)

`DiffableDataSource` 提供了两种更新 item 的方式，`adapter` 对它们进行了封装：

*   **`reload(_:animatingDifferences:)`**: 重新加载一个 item。这会 **销毁并重新创建** 对应的 `UITableViewCell` 实例。当 item 的数据变化 **导致 cell 高度或类型需要改变** 时，应使用此方法。

    ```swift
    // ModernViewController.swift -> demoClosureHeightChange()

    // isFavorite 的变化会影响闭包计算的高度，因此使用 reload
    var item = favorites[0]
    item.isFavorite.toggle()
    adapter.reload(item, animatingDifferences: true)
    ```

*   **`reconfigure(_:animatingDifferences:)`**: 重新配置一个 item。这会 **复用** 现有的 `UITableViewCell` 实例，仅重新调用 `cellBuilder` 闭包来更新其内容。当 item 的数据变化 **不影响 cell 高度或类型** 时，使用此方法性能更高。

    ```swift
    // ModernViewController.swift -> demoReconfigureNoHeightChange()

    // isFavorite 的变化不影响 NewSongTableViewCell 的高度，因此使用 reconfigure
    var target = pop.first!
    target.isFavorite.toggle()
    adapter.reconfigure(target, animatingDifferences: true)
    ```

---

## 3. 高度管理

`DiffableTableAdapter` 还提供了一套优雅的机制来管理 `UITableViewCell` 的高度，支持自动布局和手动闭包计算两种模式。

### a. 自动高度 (Auto Layout)

如果你的 cell 使用 Auto Layout 约束来确定其高度，只需调用 `enableAutomaticDimension`。

```swift
// ModernViewController.swift -> configureHeightMode()

// 切换到自动高度模式
adapter.enableAutomaticDimension(estimatedRowHeight: 80)
// 清除闭包，让 UITableView.automaticDimension 生效
adapter.setHeightProviders(height: nil, estimated: nil)
```

然后在 `UITableViewDelegate` 中返回 `UITableView.automaticDimension`。

```swift
// ModernViewController.swift

func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
}
```

### b. 闭包高度 (手动计算)

对于需要精确控制高度或有复杂计算逻辑的场景，可以使用 `setHeightProviders` 提供一个闭包。

```swift
// ModernViewController.swift -> configureHeightMode()

// 切换到闭包高度模式
tableView.rowHeight = 60 // 提供一个默认值
adapter.setHeightProviders(height: { tableView, indexPath, song, section in
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
}, estimated: { /* ... 提供预估高度 ... */ })
```

然后在 `UITableViewDelegate` 中，调用 `adapter` 的方法来获取计算好的高度。

```swift
// ModernViewController.swift

func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    // 从 adapter 获取闭包计算的高度，如果失败则回退到 tableView 的默认行高
    return adapter.heightForRow(at: indexPath) ?? tableView.rowHeight
}

func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return adapter.estimatedHeightForRow(at: indexPath) ?? tableView.estimatedRowHeight
}
```

**关键点**:

*   `heightForRow(at:)` 和 `estimatedHeightForRow(at:)` 方法会安全地解析 `indexPath` 对应的 `Item` 和 `Section`，然后调用你提供的闭包。
*   这种模式将高度计算逻辑与 `ViewController` 的 `delegate` 方法解耦，使代码更清晰。

## 总结

`DiffableDataSourceKit` 通过 `BaseReorderableDiffableDataSource` 和 `DiffableTableAdapter` 两个组件，极大地简化了 `UITableViewDiffableDataSource` 的使用。它提供了更清晰的 API、更少的手动操作，并优雅地处理了分区逻辑、数据更新和行高计算等常见任务。