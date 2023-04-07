//
//  PeopleCell.swift
//  Scorp
//
//  Created by Güney Köse on 5.04.2023.
//

import UIKit

class PeopleCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    public func setCell(person: Person) {
        nameLabel.text = "\(person.fullName) (\(person.id))"
    }
}
