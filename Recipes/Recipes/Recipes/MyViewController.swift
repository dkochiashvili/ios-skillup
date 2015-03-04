//
//  ViewController.swift
//  Recipes
//
//  Created by Davit on 2/14/15.
//  Copyright (c) 2015 Davit. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

func UIColorFromRGB(rgbValue: UInt) -> UIColor {
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

class MyViewController: UITableViewController,UITableViewDataSource,NSFetchedResultsControllerDelegate,UISearchBarDelegate,UITableViewDelegate {
    var data: ModelRecipes?
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        data = ModelRecipes()
        data?.fetchedResultsController.delegate = self
        searchBar.delegate = self
        
    
        let tap = UITapGestureRecognizer(target: self, action: "onTap:")
        //tableView.addGestureRecognizer(tap)
        
        println(NSStringFromClass(self.dynamicType))
        
        tableView.allowsSelection = true
        tableView.delegate = self
    }
    
    func onTap(event: UITapGestureRecognizer){
        setFilterBySearch(searchBar.text)
        searchBar.resignFirstResponder()
    
    }
    
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.toolbarHidden = true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setFilterBySearch(text: String?){
        data?.filterShortName = text
        tableView.reloadData()
    }
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        setFilterBySearch(searchText)
    }
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return data?.fetchedResultsController.sections?.count ?? 0
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = data?.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return section.numberOfObjects
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if searchBar.isFirstResponder() {
            searchBar.resignFirstResponder()
        } else {
            performSegueWithIdentifier("editRecipe", sender: indexPath)
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("recipecell", forIndexPath: indexPath) as RecipeCell
        configureCell(cell, atIndexPath: indexPath)
        if (indexPath.row % 2) == 0 {
            cell.backgroundColor = UIColorFromRGB(0xBBEEBB)
            cell.contentView.backgroundColor = UIColorFromRGB(0xBBEEBB)
        } else {
            cell.backgroundColor = UIColorFromRGB(0xCCFFCC)
            cell.contentView.backgroundColor = UIColorFromRGB(0xCCFFCC)
        }
        return cell
    }
    

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            data?.removeFromFetchedResults(atIndexPath: indexPath)
           
        }
    }
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = data?.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
        let recipeCell = cell as RecipeCell
        recipeCell.lblDescription!.text = object.valueForKey("shortDescr")!.description
        //recipeCell.txtPreparation!.text = object.valueForKey("preparation")!.description
        
        if let obj: AnyObject = object.valueForKey("imageLocation") {
            if obj.description != nil {
                recipeCell.theImage?.image = UIImage(contentsOfFile: "\(glPicturePath)/\(obj.description)")
            }
        }
        if recipeCell.superview == self {
            println("view are same")
        }
        
        
        recipeCell.locButton.hidden = true
        recipeCell.locButton.tag = indexPath.row
        
        if let crd: NSNumber =  object.valueForKey("isLocationPresent") as? NSNumber {
            recipeCell.locButton.hidden = !crd.boolValue
            if crd.boolValue {
                recipeCell.coords = CLLocationCoordinate2D(
                    latitude: (object.valueForKey("crdLat") as NSNumber).doubleValue,
                    longitude: (object.valueForKey("crdLon") as NSNumber).doubleValue)
                //println("configure cell coords \(recipeCell.coords?.latitude)")
            } else {
                recipeCell.coords = nil
            }
            
        }
        recipeCell.supView = self
    }
    
    @IBAction func go2addRecipe(sender: AnyObject) {
        self.performSegueWithIdentifier("addRecipe", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "location" {
            let dst = segue.destinationViewController as MapViewController
            if let recpcell = sender as? RecipeCell {
                dst.coord = recpcell.coords
            }         
        } else if segue.identifier == "editRecipe" {
            let dst = segue.destinationViewController as AddNewRecipeController
            let object = data?.fetchedResultsController.objectAtIndexPath(sender as NSIndexPath) as NSManagedObject
            
            dst.recipeManagedObject = object
        }
    }
 
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

    
    
    
    
}

