//
//  NodeCell.swift
//  etzwallet
//
//  Created by etz on 2019/1/18.
//  Copyright © 2019年 etzwallet LLC. All rights reserved.
//

import UIKit

class NodeCell : UITableViewCell {
    
    private let nodeLabel = UILabel(font: .customBody(size: 16.0), color: .darkText)
    private let icon = UIImageView()
    private let separator = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    func set(item: NodeItem) {
        nodeLabel.text = item.node
        separator.backgroundColor = .separator
        icon.image = UIImage(named: item.thumbnail)
    }
    
    private func setup() {
        addSubviews()
        addConstraints()
    }
    
    private func addSubviews() {
        contentView.addSubview(nodeLabel)
        contentView.addSubview(icon)
        contentView.addSubview(separator)
    }
    
    private func addConstraints() {
        icon.constrain([
            icon.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: C.padding[2]),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
        
        nodeLabel.constrain([
            nodeLabel.heightAnchor.constraint(equalToConstant: 28.0),
            nodeLabel.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: C.padding[2]),
            nodeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
        
        separator.constrain([
            separator.rightAnchor.constraint(equalTo: contentView.rightAnchor,constant: C.padding[5]),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.leftAnchor.constraint(equalTo: icon.rightAnchor,constant: C.padding[2]),
            separator.heightAnchor.constraint(equalToConstant: 1.0) ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
