//
//  CollectionViewController.swift
//  Breaze
//
//  Created by Joseph Hardy on 4/27/25.
//  Copyright 2025 Carquinez. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class CollectionViewController: ArchiveSuperViewController, UITableViewDelegate, UITableViewDataSource {
    var selectedCollection: String?
    private let store = CollectionStore()
    private var entries: [CollectionEntry] = []
    private var addButtonItem: UIBarButtonItem?
    private var browseButtonItem: UIBarButtonItem?
    
    @IBOutlet weak var tableView: UITableView! // Connect this in your storyboard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        setNavButtons()
        entries = store.getEntries()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionCell", for: indexPath)
        cell.textLabel?.text = entries[indexPath.row].displayName
        cell.textLabel?.applyTextStyle(AppFonts.title)
        return cell
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CollectionToYearsSegue" {
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            print(indexPath)
            if let destinationVC = segue.destination as? YearViewController {
                destinationVC.selectedCollection = entries[indexPath.row].identifier
                print(indexPath.row)
                print(destinationVC.selectedCollection as Any)
            }
        }
    }

    // MARK: - Edit / Delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let entry = entries[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            guard let self = self else { return }
            self.store.removeCollection(entry)
            self.entries = self.store.getEntries()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    // MARK: - Add
    @objc private func addCollectionTapped() {
        let alert = UIAlertController(title: "Add Band", message: "Enter display name and identifier (collection or creator)", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Display Name (e.g., Widespread Panic)" }
        alert.addTextField { $0.placeholder = "Identifier (e.g., WidespreadPanic)" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let id = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty, !id.isEmpty else { return }
            self.addCollectionAndInferYears(displayName: name, identifier: id)
        }))
        present(alert, animated: true)
    }

    // MARK: - Browse and Fetch All Collections
    @objc private func browseCollectionsTapped() {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        archiveAPI.fetchEtreeCollections { [weak self] collections, error in
            DispatchQueue.main.async { self?.setNavButtons() }
            if let error = error { print("fetchEtreeCollections error: \(error.localizedDescription)"); return }
            guard let collections = collections else { return }
            DispatchQueue.main.async {
                self?.presentCollectionsPicker(collections: collections)
            }
        }
    }

    private func presentCollectionsPicker(collections: [ArchiveAPI.ArchiveCollection]) {
        let picker = CollectionsPickerViewController(collections: collections.sorted { (a, b) -> Bool in
            let at = (a.title ?? a.identifier) ?? ""
            let bt = (b.title ?? b.identifier) ?? ""
            return at.localizedCaseInsensitiveCompare(bt) == .orderedAscending
        }) { [weak self] selected in
            let title = (selected.title ?? selected.identifier) ?? "Unknown"
            let id = selected.identifier ?? title
            self?.addCollectionAndInferYears(displayName: title, identifier: id)
        }
        let nav = UINavigationController(rootViewController: picker)
        present(nav, animated: true)
    }

    // Add then infer whether creator-based and compute year range to persist for YearViewController
    private func addCollectionAndInferYears(displayName: String, identifier: String) {
        archiveAPI.detectCreatorBased(collectionOrCreator: identifier) { [weak self] isCreator in
            // Persist creator-based override if needed
            if isCreator {
                let defaults = UserDefaults.standard
                var extra = defaults.stringArray(forKey: "creatorBasedCollectionsExtra") ?? []
                if !extra.contains(identifier) {
                    extra.append(identifier)
                    defaults.set(extra, forKey: "creatorBasedCollectionsExtra")
                }
            }
            self?.archiveAPI.fetchCollectionYearRange(identifier: identifier, isCreatorBased: isCreator) { range in
                let defaults = UserDefaults.standard
                if let (minY, maxY) = range {
                    defaults.set([minY, maxY], forKey: "years_\(identifier)")
                }
                DispatchQueue.main.async {
                    self?.store.addCollection(displayName: displayName, identifier: identifier)
                    self?.entries = self?.store.getEntries() ?? []
                    self?.tableView.reloadData()
                }
            }
        }
    }

    private func setNavButtons() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCollectionTapped))
        let browseButton = UIBarButtonItem(title: "Browse", style: .plain, target: self, action: #selector(browseCollectionsTapped))
        self.addButtonItem = addButton
        self.browseButtonItem = browseButton
        navigationItem.rightBarButtonItems = [addButton, browseButton]
    }
}
