import UIKit
import CoreData

class ContactListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var contacts = [NSManagedObject]()
    var filteredContact = [NSManagedObject]()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set tableview datasource and delegate
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()

        setUpSearchBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchContacts()
        tableView.reloadData()
    }
    
    private func fetchContacts() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedObjectContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Contact")
        
        do {
            contacts = try managedObjectContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could nt fetch the data \(error.description) ")
        }
    }

    private func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredContact = contacts.filter({( contact : NSManagedObject) -> Bool in
            let name = (contact.value(forKey: "firstName")) as! String
            return name.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    private func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    private func setUpSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search contact here..."
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
}

extension ContactListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredContact.count
        }
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath)
        var contact: NSManagedObject
        if isFiltering() {
            contact = filteredContact[indexPath.row]
        }
        contact = contacts[indexPath.row]
        
        if let firstName = contact.value(forKey: "firstName") as? String,
            let lastName = contact.value(forKey: "lastName") as? String {
            
            let fullName = firstName.appending(" \(lastName)")
            let contactImage = UIImage(data: contact.value(forKey: "image") as! Data)
            
            cell.imageView?.setUp()
            
            cell.textLabel?.text = fullName
            cell.detailTextLabel?.text = contact.value(forKey: "email") as? String
            cell.imageView?.image = contactImage
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
}

extension ContactListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            return
        }
        filterContentForSearchText(searchText)
    }
}
