//: Playground - noun: a place where people can play

import UIKit

let a = UITableView()
print("a = \(a.dynamicType)")
let b = UICollectionView(frame: CGRect(), collectionViewLayout: UICollectionViewFlowLayout())
print("b = \(b.dynamicType)")
let c = UIScrollView()
print("c = \(c.dynamicType)")

print(a.dynamicType == UIScrollView.self)
print(a.dynamicType == UITableView.self)
print(b.dynamicType == UIScrollView.self)
print(c.dynamicType == UIScrollView.self)
