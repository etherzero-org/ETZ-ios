//
//  ETZNodeSelectorViewController.swift
//  etzwallet
//
//  Created by etz on 2019/1/17.
//  Copyright © 2019年 etzwallet LLC. All rights reserved.
//

import Foundation
import UIKit
import BRCore
import SwiftyJSON

class ETZNodeSelectorViewController : UITableViewController, Trackable, Subscriber {
    
    init(walletManager: BTCWalletManager) {
        self.walletManager = walletManager
        self.nodeItems = NSMutableArray()
        let item1 = NodeItem(regon: S.Region.Singapore, node: "etzrpc.org:443",thumbnail:"Singapore")
        let item2 = NodeItem(regon: S.Region.Singapore, node: "sg.etznumberone.com:443",thumbnail:"Singapore")
        let item3 = NodeItem(regon: S.Region.USA, node: "usa.etznumberone.com:443",thumbnail:"USA")
        let item4 = NodeItem(regon: S.Region.HongKong, node: "47.90.101.201:9646",thumbnail:"HongKong")
        self.nodeItems.addObjects(from: [item1,item2,item3,item4])
        super.init(style: .plain)
    }
    
    private let walletManager: BTCWalletManager
    private let cellIdentifier = "ETZNodeCellIdentifier"
    private let nodeItems:NSMutableArray
    private var header: UIView?
    
    private let node = UILabel(font: .customBody(size: 14.0), color: .darkText)
    
    deinit {
        Store.unsubscribe(self)
    }
    
    override func viewDidLoad() {
        tableView.register(NodeCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 140.0
        tableView.backgroundColor = .whiteTint
        tableView.separatorStyle = .none
        
        let titleLabel = UILabel(font: .customBold(size: 17.0), color: .darkText)
        titleLabel.text = S.Settings.currency
        titleLabel.sizeToFit()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nodeItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:NodeCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! NodeCell
        let item:NodeItem = self.nodeItems[indexPath.row] as! NodeItem
        cell.set(item: item)
//        cell.textLabel?.text = item.node
        if (UserDefaults.standard.object(forKey: "baseUrl") as! String).contains(item.node) {
            let check = UIImageView(image: #imageLiteral(resourceName: "CircleCheck").withRenderingMode(.alwaysTemplate))
            check.tintColor = C.defaultTintColor
            cell.accessoryView = check
        } else {
            cell.accessoryView = nil
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let header = self.header { return header }
        
        let header = UIView(color: .whiteTint)
        let titleLabel = UILabel(font: .customBold(size: 26.0), color: .darkText)
        let nodeLabel = UILabel(font: .customBody(size: 14.0), color: .grayTextTint)
        let statusLabel = UILabel(font: .customBody(size: 14.0), color: .grayTextTint)
        let status = UILabel(font: .customBody(size: 14.0), color: .darkText)

        header.addSubview(titleLabel)
        header.addSubview(nodeLabel)
        header.addSubview(node)
        header.addSubview(statusLabel)
        header.addSubview(status)

        titleLabel.constrain([
            titleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: C.padding[6]),
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: C.padding[2]),
            titleLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -C.padding[2])
            ])

        titleLabel.text = S.NodeSelector.etzTitle
        titleLabel.textAlignment = .right
        nodeLabel.text = S.NodeSelector.nodeLabel
        statusLabel.text = S.NodeSelector.statusLabel

        status.text = walletManager.peerManager?.connectionStatus.description
        node.text = (UserDefaults.standard.object(forKey: "baseUrl") as! String)
        
        nodeLabel.constrain([
            nodeLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: C.padding[2]),
            nodeLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: C.padding[1])])
        node.constrain([
            node.leadingAnchor.constraint(equalTo: nodeLabel.leadingAnchor),
            node.topAnchor.constraint(equalTo: nodeLabel.bottomAnchor) ])
        
        statusLabel.constrain([
            statusLabel.leadingAnchor.constraint(equalTo: nodeLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: node.bottomAnchor, constant: C.padding[2]) ])
        status.constrain([
            status.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            status.topAnchor.constraint(equalTo: statusLabel.bottomAnchor),
            status.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -C.padding[2]),
            status.widthAnchor.constraint(equalTo: header.widthAnchor, constant: -C.padding[4]) ])
        
        self.header = header
        return header
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item:NodeItem = nodeItems[indexPath.row] as! NodeItem
        if !item.node.contains("47.90.101.201:9646") {
            UserDefaults.standard.set(item.node, forKey: "baseUrl")
            node.text = item.node
        }
        tableView.reloadData()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
