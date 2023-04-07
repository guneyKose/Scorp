//
//  ViewController.swift
//  Scorp
//
//  Created by Güney Köse on 5.04.2023.
//

import UIKit

protocol ViewModelToController: AnyObject {
    func handleError(error: String, end: Bool)
}

class ViewController: UIViewController {
    
    var peopleTable: UITableView!
    var activityIndicator: UIActivityIndicatorView!
    var noOneHereLabel: UILabel!
    var refreshControl: UIRefreshControl!
    
    var timer: Timer?
    
    let viewModel = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        self.viewModel.fetchPeople { success in
                self.loadingCompleted(success)
        }
    }
    
    private func setup() {
        DispatchQueue.main.async {
            self.viewModel.delegate = self
            self.navigationItem.title = self.viewModel.title
            self.setupTableView()
            self.noOneHereLabel = UILabel()
            self.noOneHereLabel.frame = self.view.frame
            self.noOneHereLabel.text = self.viewModel.noOneHereText
            self.noOneHereLabel.textAlignment = .center
            self.view.addSubview(self.noOneHereLabel)
        }
    }
    
    private func setupTableView() {
        DispatchQueue.main.async {
            self.peopleTable = UITableView(frame: self.view.bounds)
            self.view.addSubview(self.peopleTable)
            self.peopleTable.delegate = self
            self.peopleTable.dataSource = self
            self.peopleTable.register(self.viewModel.cellNib, forCellReuseIdentifier: PeopleCell.id)
            self.refreshControl = UIRefreshControl()
            self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
            self.refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
            self.peopleTable.addSubview(self.refreshControl)
            self.setupActivityIndicator()
        }
    }
    
    private func setupActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator = UIActivityIndicatorView(frame: self.view.frame)
            self.activityIndicator.style = .large
            self.activityIndicator.color = .label
            self.activityIndicator.startAnimating()
            self.view.addSubview(self.activityIndicator)
        }
    }
    
    private func loadingCompleted(_ success: Bool) {
        DispatchQueue.main.async {
            if success {
                self.peopleTable.reloadData()
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
            }
            self.noOneHereLabel.isHidden = !(self.viewModel.people.count == 1)
        }
    }
    
    private func scrollToBottom() {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.viewModel.people.count-1, section: 0)
            self.peopleTable.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    //Restart the list.
    @objc func refresh(_ sender: AnyObject) {
        self.viewModel.fetchPeople(isRefresh: true) { success in
            self.loadingCompleted(success)
            self.refreshControl.endRefreshing()
            return
        }
        //Timeout...
        self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
                self.handleError(error: "Time Out", end: false)
            }
            timer.invalidate()
            self.timer = nil
        })
    }
}

//MARK: - TableView
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.people.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PeopleCell.id, for: indexPath)
                as? PeopleCell else { fatalError(PeopleCell.id) }
        cell.setCell(person: viewModel.people[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.people.count - 6 &&
            !viewModel.isLoading &&
            !viewModel.didReachedEnd { //Fetch more people.
            DispatchQueue.main.async {
                tableView.reloadData()
            }
            viewModel.fetchPeople { success in
                self.loadingCompleted(success)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

//MARK: - ViewModelToController
extension ViewController: ViewModelToController {
    func handleError(error: String, end: Bool) {
        let actionTitle = end ? "OK" : "Try again"
        let alert = UIAlertController(title: error,
                                      message: "Try again later.",
                                      preferredStyle: .alert)
        let alertAction = UIAlertAction(title: actionTitle, style: .default) { _ in
            if !end {
                self.viewModel.fetchPeople { success in
                    self.loadingCompleted(success)
                }
            } else {
                self.scrollToBottom()
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(alertAction)
        if !end { alert.addAction(cancel) }
        self.present(alert, animated: true)
    }
}
