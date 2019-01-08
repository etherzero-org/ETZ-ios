//
//  ETZMineViewController.swift
//  etzwallet
//
//  Created by etz on 2018/12/25.
//  Copyright © 2018年 etzwallet LLC. All rights reserved.
//

import UIKit

enum MineSections: String {
    case wallet
    case preferences
    case currencies
    case other
    case currency
    case network
    
    var title: String {
        switch self {
        case .wallet:
            return S.Settings.wallet
        case .preferences:
            return S.Settings.preferences
        case .currencies:
            return S.Settings.currencySettings
        case .other:
            return S.Settings.other
        default:
            return ""
        }
    }
}

class ETZMineViewController: UITableViewController ,CustomTitleView{
    
    init(sections: [MineSections], rows: [MineSections: [Setting]], optionalTitle: String? = nil) {
        self.sections = sections
        self.rows = rows
        customTitle = optionalTitle ?? S.Settings.title
        titleLabel.text = optionalTitle ?? S.Settings.title
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let sections: [MineSections]
    private let rows: [MineSections: [Setting]]
    private let cellIdentifier = "MineCellIdentifier"
    let titleLabel = UILabel(font: .customBold(size: 28.0), color: .darkGray)
    let customTitle: String
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationItem.title  = "我的"
        view.backgroundColor = .white
        self.title = "我的"
    
        tableView.register(SeparatorCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .whiteBackground
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[sections[section]]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        if let setting = rows[sections[indexPath.section]]?[indexPath.row] {
            cell.textLabel?.text = setting.title
            cell.textLabel?.font = .customBody(size: 16.0)
            cell.textLabel?.textColor = .darkGray
            
            let label = UILabel(font: .customMedium(size: 16.0), color: .darkGray)
            label.text = setting.accessoryText?()
            label.sizeToFit()
            cell.accessoryView = label
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 47))
        view.backgroundColor = .whiteBackground
        let label = UILabel(font: .customMedium(size: 12.0), color: .mediumGray)
        view.addSubview(label)
        label.text = sections[section].title
        let separator = UIView()
        separator.backgroundColor = .separator
        view.addSubview(separator)
        separator.constrain([
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0) ])
        
        label.constrain([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            label.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -C.padding[1])
            ])
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let setting = rows[sections[indexPath.section]]?[indexPath.row] {
            setting.callback()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 47.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48.0
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollForCustomTitle(yOffset: scrollView.contentOffset.y)
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewWillEndDraggingForCustomTitle(yOffset: targetContentOffset.pointee.y)
    }

}
