//
//  ViewController.swift
//  AdaptiveQuran
//
//  Created by Amir Mughal on 08/04/2019.
//  Copyright © 2019 Amir Mughal. All rights reserved.
//

import UIKit

class ViewController: UIViewController  ,UITableViewDelegate, UITableViewDataSource{
    let reuseableIdentifier = "tableViewCell"
    @IBOutlet weak var surahTableView: UITableView!
    var surahCount = 0
    var userTag = -1
    var pageTitle:String?
    
    override func viewDidLoad() {
        surahCount = DBManager.shared.surahCount()
        super.viewDidLoad()
        self.title = pageTitle
        surahTableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.1826917231, green: 0.08038008958, blue: 0.2357645035, alpha: 1)
        self.navigationController?.navigationBar.tintColor = #colorLiteral(red: 0.09896145016, green: 0.7481964827, blue: 0.5541328192, alpha: 1)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return surahCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.surahTableView.dequeueReusableCell(withIdentifier: "surahCell") as! SurahTableViewCell
        cell.surahName.text = DBManager.shared.getSurahName(at: indexPath.row)
        cell.surahName.layer.cornerRadius = 10
        cell.surahName.layer.borderWidth = 1
        cell.surahName.layer.borderColor = UIColor.clear.cgColor
        cell.surahName.clipsToBounds = true
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dest = self.storyboard?.instantiateViewController(withIdentifier: "LessonsView") as! LessonsViewController
        dest.surahId = indexPath.row + 1
        dest.userTag = userTag
        self.surahTableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.pushViewController(dest, animated: true)
    }
}
