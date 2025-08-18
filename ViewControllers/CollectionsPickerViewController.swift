import UIKit

final class CollectionsPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let allCollections: [ArchiveAPI.ArchiveCollection]
    private var filtered: [ArchiveAPI.ArchiveCollection]
    private let onSelect: (ArchiveAPI.ArchiveCollection) -> Void
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar(frame: .zero)

    init(collections: [ArchiveAPI.ArchiveCollection], onSelect: @escaping (ArchiveAPI.ArchiveCollection) -> Void) {
        self.allCollections = collections
        self.filtered = collections
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Browse Bands"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))

        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        view.addSubview(searchBar)
        view.addSubview(tableView)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func closeTapped() { dismiss(animated: true) }

    // MARK: - Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return filtered.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = filtered[indexPath.row]
        cell.textLabel?.text = (item.title ?? item.identifier) ?? "Unknown"
        cell.textLabel?.applyTextStyle(AppFonts.title)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect(filtered[indexPath.row])
        dismiss(animated: true)
    }

    // MARK: - Search
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filtered = allCollections
        } else {
            let q = searchText.lowercased()
            filtered = allCollections.filter { item in
                let t = ((item.title ?? item.identifier) ?? "").lowercased()
                return t.contains(q)
            }
        }
        tableView.reloadData()
    }
}


