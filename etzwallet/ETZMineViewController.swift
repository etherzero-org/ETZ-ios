//
//  ETZMineViewController.swift
//  etzwallet
//
//  Created by etz on 2018/12/25.
//  Copyright © 2018年 etzwallet LLC. All rights reserved.
//

import UIKit

class ETZMineViewController: UIViewController ,UITableViewDelegate,UITableViewDataSource {
    private let items: [MenuItem] = []
    private var visibleItems: [MenuItem] {
        return items.filter { $0.shouldShow() }
    }
    var tableView = UITableView()
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationItem.title  = "我的"
        view.backgroundColor = .white
        self.title = "我的"
        
        self.tableView.register(MenuCell.self, forCellReuseIdentifier: MenuCell.cellIdentifier)
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .lightGray
        self.tableView.rowHeight = 48.0
    }
    
    func reloadMenu() {
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuCell.cellIdentifier, for: indexPath) as? MenuCell else { return UITableViewCell() }
        cell.set(item: visibleItems[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        visibleItems[indexPath.row].callback()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
