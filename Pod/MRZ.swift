//
//  MRZ.swift
//  PassportScanner
//
//  Created by Edwin Vermeer on 12/5/14.
//  Copyright (c) 2015. All rights reserved.
//

import Foundation

public class MRZ: NSObject {
    // check data with http://en.wikipedia.org/wiki/Machine-readable_passport
    
    /// Was the last scan valid. A value of 1 is for when all validations are OK
    public var isValid: Float = 0
    /// Do you want to see debug messages? Set to true (see init) to see what's going on.
    private var debug = false
    
    /// The document type from the 1st line of the MRZ. (start 1, len 1)
    public var documentType: String = ""
    /// The document sub type from the 1st line of the MRZ. (start 2, len 1)
    public var documentSubType: String = ""
    /// The country code from the 1st line of the MRZ (start 3, len 3)
    public var countryCode: String = ""
    /// The last name from the 1st line of the MRZ (start 6, len 39, until first <<)
    public var lastName: String = ""
    /// The firstname from the 1st line of the MRZ (start 6, len 39, after first <<)
    public var firstName: String = ""
    public var characterset = CharacterSet(charactersIn: "ABCDEFGHIJKLKMNOPQRSTUVWXYZ")
    public var passportset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
    public var genderset = CharacterSet(charactersIn: "MF")
    public var numberset = CharacterSet(charactersIn: "1234567890")
    /// The passport number from the 2nd line of the MRZ. (start 1, len 9)
    public var passportNumber: String = ""
    /// start 10, len 1 - validating the passportNumber
    private var passportNumberIsValid = false
    /// The nationality from the 2nd line of the MRZ. (start 11, len 3)
    public var nationality: String = ""
    /// The date of birth from the 2nd line of the MRZ (start 14, len 6)
    public var dateOfBirth: Date?
    /// start 20, len 1 - validating the dateOfBirth
    private var dateOfBirthIsValid = false
    /// The sex from the 2nd line of the MRZ. (start 21, len 1)
    public var sex: String = ""
    /// The expiration date from the 2nd line of the MRZ. (start 22, len 6)
    public var expirationDate: Date?
    /// start 28, len 1 - validating the expirationDate
    private var expirationDateIsValid = false
    /// The personal number from the 2nd line of the MRZ. (start 29, len 14
    public var personalNumber: String = ""
    /// start 43, len 1 - validating the personalNumber
    private var personalNumberIsValid = false
    // start 44, len 1 - validating passport number, date of birth, expirationdate
    private var dataIsValid = false
    
    
    /**
     Convenience method for getting all data in a dictionary
     
     :returns: Return all fields in a dictionary
     */
    public func data() -> Dictionary<String, Any> {
        return ["documentType": documentType, "documentSubType": documentSubType, "countryCode": countryCode, "lastName": lastName, "firstName": firstName, "passportNumber": passportNumber, "nationality": nationality, "dateOfBirth": MRZ.stringFromDate(dateOfBirth), "sex": sex, "expirationDate": MRZ.stringFromDate(expirationDate), "personalNumber": personalNumber]
    }
    
    /**
     Get the discription of the MRZ
     
     :returns: a string with all fields plus fieldname (each field on a new line)
     */
    public override var description: String {
        get {
            return self.data().map {"\($0) = \($1)"}.reduce("") {"\($0)\n\($1)"}
        }
    }
    
    /**
     Initiate the MRZ object with the scanned data.
     
     :param: scan  the scanned string
     :param: debug true if you want to see debug messages.
     
     :returns: Instance of MRZ
     */
    public init(scan: String, debug: Bool = false) {
        super.init()
        self.debug = debug
        let lines: [String] = scan.characters.split(separator: "\n").map({String($0)})
        var longLines: [String] = []
        for line in lines {
            let cleaned = line.replace(target: " ", with: "")
            if cleaned.characters.count > 43 {
                longLines.append(line)
            }
        }
        if longLines.count < 2 { return }
        if longLines.count == 2 {
            process(l1: longLines[0].replace(target: " ", with: ""), l2: longLines[1].replace(target: " ", with: ""))
        } else if longLines.last?.components(separatedBy: "<").count ?? 0 > 1 {
            process(l1: longLines[longLines.count-2], l2: longLines[longLines.count-1])
        } else {
            process(l1: longLines[longLines.count-3].replace(target: " ", with: ""), l2: longLines[longLines.count-2].replace(target: " ", with: ""))
        }
    }
    
    /**
     Do you want to see the progress in the log
     
     :param: line The data that will be loged
     */
    fileprivate func debugLog(_ line: String) {
        if debug {
            print(line)
        }
    }
    
    
    /**
     Process the 2 MRZ lines
     
     :param: l1 First line
     :param: l2 Second line
     */
    fileprivate func process(l1: String, l2: String) {
        
        let line1 = MRZ.cleanup(line: l1)
        let line2 = MRZ.cleanup(line: l2)
        
        debugLog("Processing line 1 : \(line1)")
        debugLog("Processing line 2 : \(line2)")
        
        // Line 1 parsing
        documentType = line1.subString(0, to: 1)
        debugLog("Document type : \(documentType)")
        documentSubType = line1.subString(1, to: 1)
        countryCode = line1.subString(2, to: 5).replace(target: "<", with: " ") //One string before, need to start from 2 to 5//
        if countryCode.rangeOfCharacter(from: characterset.inverted) == nil {
           isValid = isValid+1
            print("Country Code Is Valid")
        }
        
        debugLog("Country code : \(countryCode)")
        let name = line1.subString(5, to: 44).replace(target: "0", with: "O")
        var nameArray = name.components(separatedBy: "<<")
        lastName = nameArray[0].replace(target: "<", with: " ")
        if lastName.rangeOfCharacter(from: characterset.inverted) == nil {
            print("LastName Is Valid")
            isValid = isValid+1
        }
        debugLog("Lastname : \(lastName)") //Need to start from 5 to 43//
        firstName = nameArray.count > 1 ? nameArray[1].replace(target: "<", with: " ") : ""
        debugLog("Firstname : \(firstName)")
        
        // Line 2 parsing
        passportNumber = line2.subString(0, to: 8)
        debugLog("passportNumber : \(passportNumber)")
        let passportNumberCheck = line2.subString(10, to: 10)
        if passportNumberCheck.rangeOfCharacter(from: passportset.inverted) == nil {
            isValid = isValid+1
            print("Nationality Is Valid")
        }
        
        nationality = line2.subString(10, to: 13).replace(target: "<", with: " ") // Need to start from 10 to 13//
        nationality = countryCode
        debugLog("nationality : \(nationality)")
        let birth = line2.subString(13, to: 19).replace(target: "O", with: "0")
        let birthValidation = line2.subString(20, to: 20).replace(target: "O", with: "0").replace(target: "U", with: "0")
        dateOfBirth = MRZ.dateFromString(birth)
        if birthValidation.rangeOfCharacter(from: numberset.inverted) == nil {
            isValid = isValid+1
            print("Nationality Is Valid")
        }
        debugLog("date of birth : \(dateOfBirth)")
        sex = line2.subString(20, to: 21)
        if sex.rangeOfCharacter(from: genderset.inverted) == nil {
            isValid = isValid+1
            print("Gender Is Valid")
        }
        debugLog("sex : \(sex)")
        let expiration = line2.subString(21, to: 27).replace(target:"O", with: "0").replace(target: "U", with: "0")
        expirationDate = MRZ.dateFromString(expiration)
        if expiration.rangeOfCharacter(from: numberset.inverted) == nil {
            isValid = isValid+1
            print("Nationality Is Valid")
        }
        debugLog("date of expiration : \(expirationDate)")
        let expirationValidation = line2.subString(28, to: 28).replace(target:"O", with: "0")
        personalNumber =  line2.subString(28, to: 42).replace(target: "O", with: "0")
         if personalNumber == "<<<<<<<<<<<<<<"
         {
            print("No Personal Number")
            personalNumber = "Dont Have personal Number For This Country"
        }
        
        debugLog("personal number : \(personalNumber)")
        let personalNumberValidation = line2.subString(42, to: 43).replace(target: "O", with: "0")
        let data = "\(passportNumber)\(passportNumberCheck)\(birth)\(birthValidation)\(expiration)\(expirationValidation)\(personalNumber)\(personalNumberValidation)"
        let dataValidation = line2.subString(43, to: 44).replace(target: "O", with: "0")
        
        // Validation
//        isValid = 1
//        passportNumberIsValid = MRZ.validate(passportNumber, check: passportNumberCheck)
//        isValid = isValid * (passportNumberIsValid ? 1 : 0.9)
//        dateOfBirthIsValid = MRZ.validate(birth, check: birthValidation)
//        isValid = isValid * (dateOfBirthIsValid ? 1 : 0.9)
//        isValid = isValid * (MRZ.validate(expiration, check: expirationValidation) ? 1 : 0.9)
//        personalNumberIsValid = MRZ.validate(personalNumber, check: personalNumberValidation)
//        isValid = isValid * (personalNumberIsValid ? 1 : 0.9)
//        dataIsValid = MRZ.validate(data, check: dataValidation)
//        isValid = isValid * (dataIsValid ? 1 : 0.9)
//        
//        // Final cleaning up
//        documentSubType = documentSubType.replace(target: "<", with: "")
//        personalNumber = personalNumber.replace(target: "<", with: "")
    }
    
    
    /**
     Cleanup a line of text
     
     :param: line The line that needs to be cleaned up
     :returns: Returns the cleaned up text
     */
    fileprivate class func cleanup(line: String) -> String {
        var t = line.components(separatedBy: " ")
        if t.count > 1 {
            // are there extra characters added
            for p in t {
                if p.characters.count == 44 {
                    return p
                }
            }
            // was there one or more extra space added
            if "\(t[0])\(t[1])".characters.count == 44 {
                return "\(t[0])\(t[1])"
            } else if  "\(t[t.count-2])\(t[t.count-1])".characters.count == 44 {
                return "\(t[t.count-2])\(t[t.count-1])"
            } else {
                return line.replace(target: " ", with: "")
            }
        }
        return line // assume the garbage characters are at the end
    }
    
    /**
     Create a date from a string
     
     :param: value The string value that needs to be converted to a date
     
     :returns: Returns the date value for the string
     */
    fileprivate class func dateFromString(_ value: String) -> Date? {
        var date: Date?
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "YYMMdd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        let d = dateStringFormatter.date(from: value)
        if d != nil {
            date = Date(timeInterval:0, since:d!)
        }
        return date
    }
    
    /**
     Create a string from a date
     
     :param: value The Date value that needs to be converted to a string
     
     :returns: Returns the string value for the date
     */
    fileprivate class func stringFromDate(_ value: Date?) -> String {
        if value == nil {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "YYMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: value!)
    }
    
    /**
     MRZ data validation function
     
     :param: data The data that needs to be validated
     :param: check The checksum string for the validation
     
     :returns: Returns true if the data was valid
     */
    fileprivate class func validate(_ data: String, check: String) -> Bool {
        // The check digit calculation is as follows: each position is assigned a value; for the digits 0 to 9 this is the value of the digits, for the letters A to Z this is 10 to 35, for the filler < this is 0. The value of each position is then multiplied by its weight; the weight of the first position is 7, of the second it is 3, and of the third it is 1, and after that the weights repeat 7, 3, 1, etcetera. All values are added together and the remainder of the final value divided by 10 is the check digit.
        
        //debugLog("Check '\(data)' for check '\(check)'")
        var i: Int = 1
        var dc: Int = 0
        var w: [Int] = [7,3,1]
        let b0: UInt8 = "0".utf8.first!
        let b9: UInt8 = "9".utf8.first!
        let bA: UInt8 = "A".utf8.first!
        let bZ: UInt8 = "Z".utf8.first!
        let bK: UInt8 = "<".utf8.first!
        for c: UInt8 in Array(data.utf8) {
            var d: Int = 0
            if c >= b0 && c <= b9 {
                d = Int(c - b0)
            } else if c >= bA && c <= bZ {
                d = Int((10 + c) - bA)
            } else if c != bK {
                return false
            }
            dc = dc + d * w[(i-1)%3]
            //NSLog("i = \(i)   c = \(c)   d = \(d)   w = \(w[(i-1)%3])   dc = \(dc)")
            i += 1
        }
        if dc%10 != Int(check) {
            return false
        }
        //NSLog("Item was valid")
        return true
    }
}


extension String {
    /**
     Simple string extension for performing a replace
     
     :param: target     search this text
     :param: withString the text you want to replace it with
     
     :returns: the string with the replacements.
     */
    func replace(target: String, with: String) -> String {
        return self.replacingOccurrences(of: target, with: with, options: .literal, range: nil)
    }
    
    /**
     Get a substring
     
     :param: from from which character
     :param: to   to what character
     
     :returns: Return the substring
     */
    fileprivate func subString(_ from: Int, to: Int) -> String {
        let f: String.Index = self.index(self.startIndex, offsetBy: from)
        let t: String.Index = self.index(self.startIndex, offsetBy: to)
        return self.substring(with: f..<t)
    }
}
