//
//  ViewController.swift
//  MRZ Reader
//  Created by Admin on 21/12/16.
//  Copyright © kSandeepvvn. All rights reserved.
//

import UIKit

class ViewController: UIViewController, ProcessMRZ {

    /// Just put the scan result in this label.

    @IBOutlet weak var mrzText: UITextView!
    /**
     Make sure we only have the app in .Portrait
     
     :returns: .Portrait orientation
     */
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    /**
     Hide the status bar
     
     :returns: true will hide the status bar
     */
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    /**
    This function will be executed after pressing the scan button
    
    :param: sender The sender of the event
    */
    @IBAction func StartScan(sender: AnyObject) {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let scanVC: MyScanViewController = storyboard.instantiateViewController(withIdentifier: "") as! MyScanViewController
        scanVC.delegate = self
        self.present(scanVC, animated: true, completion: nil)
    }
    
    /**
    protocol function for ProcessMRZ for receiving the scanned MRZ
    
    :param: mrz The scanned MRZ
    */
    func processMRZ(mrz:MRZ) {
        self.mrzText.text = mrz.description
        mrzText.sizeToFit()
    }
}

