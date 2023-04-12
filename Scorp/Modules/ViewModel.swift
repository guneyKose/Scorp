//
//  ViewModel.swift
//  Scorp
//
//  Created by Güney Köse on 5.04.2023.
//

import Foundation
import UIKit

final class ViewModel {
    
    lazy var people: [Person] = []
    private var next: String?
    
    lazy var title = "People"
    lazy var noOneHereText = "No one here but me :)"
    lazy var noOneLeftText = "This is the end :("
    
    let cellNib = UINib(nibName: PeopleCell.id, bundle: nil)
    
    lazy var isLoading = false
    lazy var isCheckingIDs = false
    lazy var didReachedEnd: Bool = false
    
    weak var delegate: ViewModelToController?
    
    //Fetch people from data source
    public func fetchPeople(isRefresh: Bool = false, _ completion: @escaping (Bool) -> Void) {
        guard !isLoading else { return }
        DispatchQueue.global(qos: .background).async {
            self.isLoading = true
            if isRefresh { self.next = nil ; self.didReachedEnd = false }
            DataSource.fetch(next: self.next) { response, error in
                if let response { //Success
                    if let next = response.next { //There is more people.
                        self.next = next
                    } else { //No more people left.
                        self.delegate?.handleError(error: self.noOneLeftText, end: true)
                        self.didReachedEnd = true
                    }
                    self.isLoading = false
                    self.checkIDsAndAppend(isRefresh: isRefresh, response.people)
                    completion(true)
                } else if let error { //Error
                    debugPrint(error.errorDescription)
                    self.delegate?.handleError(error: error.errorDescription, end: false)
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }
    
    //Controlling duplicating IDs.
    private func checkIDsAndAppend(isRefresh: Bool, _ people: [Person]) {
        guard !isCheckingIDs else { return }
        if isRefresh { self.people.removeAll() }
        self.isCheckingIDs = true
        for person in people {
            if !self.people.contains(where: { $0.id == person.id } ) {
                self.people.append(person) //Has unique ID
            }
        }
        
        self.appendMe()
        self.isCheckingIDs = false
    }
    
    //Appending myself :)
    private func appendMe() {
        let me = Person(id: 0, fullName: "Güney Köse")
        if people.isEmpty {
            people.append(me)
        } else if people[0].id != me.id {
            people.insert(me, at: 0)
        }
    }
}
