//
//  LessonsViewController.swift
//  AdaptiveQuran
//
//  Created by Amir Mughal on 26/04/2019.
//  Copyright © 2019 Amir Mughal. All rights reserved.
//

import UIKit

class LessonsViewController: UIViewController ,UITableViewDataSource,UITableViewDelegate{

    let reuseableIdentifier = "LessonsCell"
    let lessons = ["Lesson 1","Lesson 2","Lesson 3"]
    @IBOutlet weak var lessonsTableView: UITableView!
    var surahId: Int = -1
    var userTag = -1
    var selectedUserLessons = [3,2,1]
    var totalAyahCount = -1
    var verseByVerseCheck:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lessonsTableView.separatorStyle = .none
        totalAyahCount = DBManager.shared.ayahCount(surahId: surahId)
        self.title = "Lessons"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedUserLessons[userTag]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.lessonsTableView.dequeueReusableCell(withIdentifier: "lessonCell") as! LessonNumberTableViewCell
        
        cell.lessonLabel.text = lessons[indexPath.row]
        cell.lessonLabel.layer.cornerRadius = 10
        cell.lessonLabel.layer.borderWidth = 1
        cell.lessonLabel.layer.borderColor = UIColor.clear.cgColor
        cell.lessonLabel.clipsToBounds = true
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dest = self.storyboard?.instantiateViewController(withIdentifier: "LessonView") as! LessonViewController
        dest.allocatedayahIds = allocateAyahs(lessonIndex: indexPath.row + 1)
        dest.userTag = userTag
        dest.surahId = surahId
        dest.callback = { result in
            self.verseByVerseCheck = result
        }
        dest.verseByVerseSelectionCheck = self.verseByVerseCheck
        self.lessonsTableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.pushViewController(dest, animated: true)
    }
    func allocateAyahs(lessonIndex: Int) -> [Int]{
        let ayahCount:Int = totalAyahCount/selectedUserLessons[userTag]
        var ayahsTobeAllocated = [Int]()
        if(lessonIndex != selectedUserLessons[userTag]){
            ayahsTobeAllocated = findAyahIndices(start: ayahCount*(lessonIndex-1), end: (lessonIndex*ayahCount))
        }
        else{
            ayahsTobeAllocated = findAyahIndices(start: (ayahCount*(lessonIndex-1)), end: totalAyahCount)
        }
        return ayahsTobeAllocated
    }
    func findAyahIndices(start: Int, end: Int) -> [Int]{
        var ayahsTobeAllocated = [Int]()
        for i in start..<end{
            ayahsTobeAllocated.append(i + 1)
        }
        return ayahsTobeAllocated
    }
}
