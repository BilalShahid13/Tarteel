//
//  UserTypeViewController.swift
//  AdaptiveQuran
//
//  Created by Amir Mughal on 20/05/2019.
//  Copyright © 2019 Amir Mughal. All rights reserved.
//

import UIKit

class UserTypeViewController: UIViewController {

    @IBOutlet weak var beginnerButton: UIButton!
    @IBOutlet weak var intermediateButton: UIButton!
    @IBOutlet weak var expertButton: UIButton!
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.2076816559, green: 0.09500940889, blue: 0.2680914998, alpha: 1)
        self.navigationController?.navigationBar.isHidden = true
        
        beginnerButton.alpha = 0.95
        intermediateButton.alpha = 0.95
        expertButton.alpha = 0.95
        
        roundTheBorder(beginnerButton)
        roundTheBorder(intermediateButton)
        roundTheBorder(expertButton)
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.title = "Home"
        self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.2076816559, green: 0.09500940889, blue: 0.2680914998, alpha: 1)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction func userTypeSelection(_ sender: UIButton) {
        let dest = self.storyboard?.instantiateViewController(withIdentifier: "Surahs View") as! ViewController
        dest.userTag = sender.tag
        dest.pageTitle = (sender.titleLabel?.text)
        self.navigationController?.pushViewController(dest, animated: true)
    }
    
    func roundTheBorder(_ button:UIButton)
    {
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.clear.cgColor
    }
}
