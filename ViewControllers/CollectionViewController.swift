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
    
    @IBOutlet weak var tableView: UITableView! // Connect this in your storyboard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCollectionTapped))
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
            self.store.addCollection(displayName: name, identifier: id)
            self.entries = self.store.getEntries()
            self.tableView.reloadData()
        }))
        present(alert, animated: true)
    }
}
