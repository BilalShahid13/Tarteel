//
//  DBManager.swift
//  AdaptiveQuran
//
//  Created by Amir Mughal on 20/05/2019.
//  Copyright © 2019 Amir Mughal. All rights reserved.
//

import UIKit
import FMDB

class DBManager: NSObject {
    static let shared: DBManager = DBManager()
    let databaseFileName = "Quran.db"
    let col_phrase = "phrase"
    let col_phrase_id = "phrase_id"
    var pathToDatabase: String!
    var surahName=[String]()
    var database: FMDatabase!
    
    override init(){
        super.init()
        openDatabase()
        readSurahNames()
    }
    func openDatabase() {
        pathToDatabase = Bundle.main.resourceURL?.appendingPathComponent(databaseFileName).path
        let database = FMDatabase(path: pathToDatabase)
        
        /* Open database read-only. */
        if (!database.open(withFlags: 1)) {
            print("Could not open database at \(pathToDatabase ?? "").")
        } else {
            self.database = database;
            print("Loaded")
        }
    }
    func loadData(){
        let query = "select * from Quran"
        do {
            let results = try database.executeQuery(query, values: nil)
            while results.next(){
                print(results.string(forColumn: col_phrase)!)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    func surahCount() -> Int{
        let query = "select count(distinct surah_id) from Quran"
        do {
            let results = try database.executeQuery(query, values: nil)
            if results.next(){
                return Int(results.int(forColumnIndex: 0))
            }
        }
        catch {
            print(error.localizedDescription)
        }
        return -1
    }
    func ayahCount(surahId: Int) -> Int{
        let query = "select count(distinct ayah_id) from Quran where surah_id = ?"
        do {
            let results = try database.executeQuery(query, values: [surahId])
            if results.next(){
                return Int(results.int(forColumnIndex: 0))
            }
        }
        catch {
            print(error.localizedDescription)
        }
        return -1
    }
    func getSelectedSurahVerses(surahId: Int, ayahs:[Int]) -> [String]{
        let query = "select phrase from Quran where surah_id = ? and ayah_id = ?"
        var allocatedVerses = [String]()
        var allocatedPhrases:String = ""
        do {
            for ayahId in 0..<ayahs.count{
                allocatedPhrases = ""
                let results = try database.executeQuery(query, values: [surahId,ayahs[ayahId]])
                while results.next(){
                    allocatedPhrases += (results.string(forColumn: col_phrase)!) + " "
                }
                allocatedVerses.append(allocatedPhrases)
            }
        }
        catch {
            print(error.localizedDescription)
        }
        return allocatedVerses
    }
    func getSelectedSurahPhrases(surahId: Int, ayahs:[Int]) -> [String]{
        let query = "select phrase from Quran where surah_id = ? and ayah_id = ?"
        var allocatedPhrases = [String]()
        do {
            for ayahId in 0..<ayahs.count{
                let results = try database.executeQuery(query, values: [surahId,ayahs[ayahId]])
                while results.next(){
                    allocatedPhrases.append(results.string(forColumn: col_phrase)!)
                }
            }
        }
        catch {
            print(error.localizedDescription)
        }
        return allocatedPhrases
    }
    func getSelectedSurahPhrasesIds(surahId: Int, ayahs:[Int]) -> [Int]{
        let query = "select phrase_id from Quran where surah_id = ? and ayah_id = ?"
        var allocatedPhrasesIds = [Int]()
        do {
            for ayahId in 0..<ayahs.count{
                let results = try database.executeQuery(query, values: [surahId,ayahs[ayahId]])
                while results.next(){
                    allocatedPhrasesIds.append(Int(results.int(forColumn: col_phrase_id)))
                }
            }
        }
        catch {
            print(error.localizedDescription)
        }
        return allocatedPhrasesIds
    }
    func getSelectedSurahVerseIds(surahId: Int, ayahs:[Int]) -> [Int]{
        var allocatedVersesIds = [Int]()
        for ayahId in 0..<ayahs.count{
            allocatedVersesIds.append(ayahs[ayahId])
        }
        return allocatedVersesIds
    }
    func readDataFromCSV(fileName:String, fileType: String)-> String!{
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
            else {
                return nil
        }
        do {
            var contents = try String(contentsOfFile: filepath, encoding: .utf8)
            contents = contents.replacingOccurrences(of: "\"", with: "")
            return contents
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }
    func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ",")
            result.append(columns)
        }
        return result
    }
    
    func readSurahNames(){
        let surahData=readDataFromCSV(fileName: "surahNames", fileType: "csv")
        let surahRows = csv(data: surahData!)
        var row:Int=1
        while row<(surahRows.count-1){
            surahName.append(surahRows[row][2])
            row += 1
        }
    }
    func getSurahName(at Index: Int)->String{
        return surahName[Index]
    }
}
