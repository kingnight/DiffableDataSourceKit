#if canImport(UIKit)
// DiffableDataSourceKit.swift
// A lightweight, reusable abstraction over UITableViewDiffableDataSource to adapt different models, sections, and cell types.
// This file provides:
// 1) A generic, reorderable data source subclass that prevents cross-section moves and centralizes logging
// 2) A simple adapter to perform common snapshot operations (add/delete/move/shuffle/reconfigure)

import UIKit

/// A generic, reorderable diffable data source.
/// - Supports section-aware cell building via a static factory method.
/// - Prevents cross-section moves by default (configurable).
/// - Adds optional logging to trace reordering and snapshot applications.
public final class BaseReorderableDiffableDataSource<Section: Hashable, Item: Hashable>: UITableViewDiffableDataSource<Section, Item> {
    // MARK: - Configuration
    public var allowCrossSectionMove: Bool = false
    public var enableLogging: Bool = false

    // MARK: - Factory
    /// Create a data source with a section-aware cell builder.
    /// This pattern avoids capturing `self` in the initializer by using a local variable capture.
    /// - Parameters:
    ///   - tableView: Target table view
    ///   - allowCrossSectionMove: Whether reordering can move rows across sections (default: false)
    ///   - enableLogging: Enable debug print logs
    ///   - cellBuilder: A builder closure that receives tableView, indexPath, item, and section (if available)
    /// - Returns: Configured BaseReorderableDiffableDataSource
    public static func create(
        tableView: UITableView,
        allowCrossSectionMove: Bool = false,
        enableLogging: Bool = false,
        cellBuilder: @escaping (UITableView, IndexPath, Item, Section?) -> UITableViewCell
    ) -> BaseReorderableDiffableDataSource<Section, Item> {
        var ds: BaseReorderableDiffableDataSource<Section, Item>!
        ds = BaseReorderableDiffableDataSource<Section, Item>(tableView: tableView) { tableView, indexPath, item in
            let section = ds.sectionIdentifier(for: indexPath.section)
            return cellBuilder(tableView, indexPath, item, section)
        }
        ds.allowCrossSectionMove = allowCrossSectionMove
        ds.enableLogging = enableLogging
        return ds
    }

    // MARK: - Reordering
    public override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if enableLogging { print("[BaseReorderable] canMoveRowAt: \(indexPath)") }
        return true
    }

    public override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if enableLogging { print("[BaseReorderable] moveRowAt from \(sourceIndexPath) to \(destinationIndexPath)") }
        guard allowCrossSectionMove || sourceIndexPath.section == destinationIndexPath.section else {
            if enableLogging { print("[BaseReorderable] Cross-section move prevented.") }
            apply(snapshot(), animatingDifferences: false)
            return
        }

        var snap = snapshot()
        let section = snap.sectionIdentifiers[sourceIndexPath.section]
        var items = snap.itemIdentifiers(inSection: section)
        let movedItem = items.remove(at: sourceIndexPath.row)
        items.insert(movedItem, at: destinationIndexPath.row)
        snap.deleteItems(snap.itemIdentifiers(inSection: section))
        snap.appendItems(items, toSection: section)
        if enableLogging { print("[BaseReorderable] Applying snapshot for reorder in section \(section)") }
        apply(snap, animatingDifferences: false)
    }
}

/// An adapter providing convenience snapshot operations for a generic diffable table.
/// Keeps your view controller lean by centralizing common mutations.
public final class DiffableTableAdapter<Section: Hashable, Item: Hashable> {
    public let tableView: UITableView
    public let dataSource: BaseReorderableDiffableDataSource<Section, Item>
    public var enableLogging: Bool = false

    public init(tableView: UITableView, dataSource: BaseReorderableDiffableDataSource<Section, Item>, enableLogging: Bool = false) {
        self.tableView = tableView
        self.dataSource = dataSource
        self.enableLogging = enableLogging
    }

    // MARK: - Setup
    /// Apply initial sections and items mapping.
    /// - Parameters:
    ///   - sections: Section order
    ///   - itemsBySection: Mapping from section to items
    ///   - animatingDifferences: Animate or not
    public func applyInitialSnapshot(
        sections: [Section],
        itemsBySection: [Section: [Item]],
        animatingDifferences: Bool = false
    ) {
        var snap = NSDiffableDataSourceSnapshot<Section, Item>()
        snap.appendSections(sections)
        for section in sections {
            if let items = itemsBySection[section] {
                snap.appendItems(items, toSection: section)
            }
        }
        if enableLogging { print("[Adapter] applyInitialSnapshot with sections: \(sections)") }
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }

    // MARK: - Mutations
    public func append(_ item: Item, to section: Section, animatingDifferences: Bool = true) {
        var snap = dataSource.snapshot()
        snap.appendItems([item], toSection: section)
        if enableLogging { print("[Adapter] append item to section: \(section)") }
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }

    public func delete(_ item: Item, animatingDifferences: Bool = true) {
        var snap = dataSource.snapshot()
        snap.deleteItems([item])
        if enableLogging { print("[Adapter] delete item") }
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }

    /// Move an item to another section by delete+append.
    public func move(_ item: Item, to section: Section, animatingDifferences: Bool = true) {
        var snap = dataSource.snapshot()
        snap.deleteItems([item])
        snap.appendItems([item], toSection: section)
        if enableLogging { print("[Adapter] move item to section: \(section)") }
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }

    /// Shuffle the order of items inside a section.
    public func shuffle(section: Section, animatingDifferences: Bool = true) {
        var snap = dataSource.snapshot()
        let items = snap.itemIdentifiers(inSection: section)
        snap.deleteItems(items)
        snap.appendItems(items.shuffled(), toSection: section)
        if enableLogging { print("[Adapter] shuffle section: \(section)") }
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }

    /// Reconfigure a single item (forces the cell provider to be re-run for that item).
    /// - Note: 使用此方法更新现有单元格的数据内容，但保留现有单元格实例。不会调用 prepareForReuse。
    /// - Important: 仅当数据内容变化但单元格高度不变时使用此方法。如需改变单元格高度或类型，请使用 reload 方法。
    /// - Parameters:
    ///   - item: 需要更新的项目
    ///   - animatingDifferences: 是否使用动画效果。默认为 true
    public func reconfigure(_ item: Item, animatingDifferences: Bool = true) {
        var snap = dataSource.snapshot()
        snap.reconfigureItems([item])
        if enableLogging { print("[Adapter] reconfigure item") }
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }

    /// Reconfigure multiple items.
    public func reconfigure(_ items: [Item], animatingDifferences: Bool = true) {
        var snap = dataSource.snapshot()
        snap.reconfigureItems(items)
        if enableLogging { print("[Adapter] reconfigure items count: \(items.count)") }
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }
    
    /// Reload a single item (creates a new cell, useful when cell height changes).
    /// - Parameters:
    ///   - item: The item to reload
    ///   - animatingDifferences: Whether to animate the changes
    public func reload(_ item: Item, animatingDifferences: Bool = true) {
        var snap = dataSource.snapshot()
        snap.reloadItems([item])
        if enableLogging { print("[Adapter] reload item") }
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }
    
    /// Reload multiple items (creates new cells, useful when cell heights change).
    /// - Parameters:
    ///   - items: The items to reload
    ///   - animatingDifferences: Whether to animate the changes
    public func reload(_ items: [Item], animatingDifferences: Bool = true) {
        var snap = dataSource.snapshot()
        snap.reloadItems(items)
        if enableLogging { print("[Adapter] reload items count: \(items.count)") }
        dataSource.apply(snap, animatingDifferences: animatingDifferences)
    }

    // MARK: - Helpers
    /// Get section identifier for a given index.
    public func sectionIdentifier(at index: Int) -> Section? {
        let snap = dataSource.snapshot()
        guard snap.sectionIdentifiers.indices.contains(index) else { return nil }
        return snap.sectionIdentifiers[index]
    }

    /// Access all items for a section.
    public func items(in section: Section) -> [Item] {
        dataSource.snapshot().itemIdentifiers(inSection: section)
    }
}
#endif
