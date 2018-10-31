/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

protocol CustomLayoutDelegate: class {
  func collectionView(_ collectionView:UICollectionView, heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat
}

final class CustomLayout: UICollectionViewLayout {
  
  enum Element: String {
    case sectionHeader
    case sectionFooter
    case cell
    
    var id: String {
      return self.rawValue
    }
  }
  
  override public class var layoutAttributesClass: AnyClass {
    return UICollectionViewLayoutAttributes.self
  }
  
  override public var collectionViewContentSize: CGSize {
    return CGSize(width: contentWidth, height: contentHeight)
  }
  
  // MARK: - Properties
  private var oldBounds = CGRect.zero
  private var contentHeight = CGFloat()
  private var cache = [Element: [IndexPath: UICollectionViewLayoutAttributes]]()
  private var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
  
  private var sectionsHeaderSize: CGSize {
    return CGSize(width: contentWidth, height: 50)
  }
  
  private var sectionsFooterSize: CGSize {
    return CGSize(width: contentWidth, height: 50)
  }
  
  fileprivate var contentWidth: CGFloat {
    guard let collectionView = collectionView else {return 0}
    let insets = collectionView.contentInset
    return collectionView.bounds.width - (insets.left + insets.right)
  }
  
  fileprivate var numberOfColumns = 2
  fileprivate var cellPadding: CGFloat = 6
  
  weak var delegate: CustomLayoutDelegate!
}

// MARK: - LAYOUT CORE PROCESS
extension CustomLayout {
  
  override public func prepare() {
    guard let collectionView = collectionView, cache.isEmpty else {return}
    
    prepareCache()
    contentHeight = 0
    oldBounds = collectionView.bounds
    
    let columnWidth = contentWidth / CGFloat(numberOfColumns)
    var xOffset = [CGFloat]()
    for column in 0 ..< numberOfColumns {
      xOffset.append(CGFloat(column) * columnWidth)
    }
    var column = 0
    var yOffset = [CGFloat](repeating: sectionsHeaderSize.height, count: numberOfColumns)
    
    for section in 0 ..< collectionView.numberOfSections {
      
      let sectionHeaderAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                                           with: IndexPath(item: 0, section: section))
      prepareElement(size: sectionsHeaderSize,type: .sectionHeader,attributes: sectionHeaderAttributes)
      
      for item in 0 ..< collectionView.numberOfItems(inSection: section) {
        
        let indexPath = IndexPath(item: item, section: section)
        let photoHeight = delegate.collectionView(collectionView, heightForPhotoAtIndexPath: indexPath)
        
        var height = cellPadding * 2 + photoHeight
        
        if column == 1 {
          yOffset[0] = max(yOffset[0], yOffset[1])
          yOffset[1] = yOffset[0]

          let previousIndexPath = IndexPath(item: item-1, section: section)
          let previousHeight = delegate.collectionView(collectionView, heightForPhotoAtIndexPath: previousIndexPath) + cellPadding * 2

          height = max(height, previousHeight)

          let previousAttributes = UICollectionViewLayoutAttributes(forCellWith: previousIndexPath)
          previousAttributes.frame = CGRect(x: xOffset[0], y: yOffset[0], width: columnWidth, height: height).insetBy(dx: cellPadding, dy: cellPadding)

          cache[.cell]?[previousIndexPath] = previousAttributes
        }
        
        let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
        let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = insetFrame
        
        contentHeight = attributes.frame.maxY
        cache[.cell]?[indexPath] = attributes
        
        yOffset[column] = yOffset[column] + height
        
        column = column < (numberOfColumns - 1) ? (column + 1) : 0
      }
      
      let sectionFooterAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
                                                           with: IndexPath(item: 1, section: section))
      prepareElement(size: sectionsFooterSize,type: .sectionFooter,attributes: sectionFooterAttributes)
    }
  }
  
  override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    if oldBounds.size != newBounds.size {
      cache.removeAll(keepingCapacity: true)
    }
    return true
  }
  
  private func prepareCache() {
    cache.removeAll(keepingCapacity: true)
    cache[.sectionHeader] = [IndexPath: UICollectionViewLayoutAttributes]()
    cache[.sectionFooter] = [IndexPath: UICollectionViewLayoutAttributes]()
    cache[.cell] = [IndexPath: UICollectionViewLayoutAttributes]()
  }
  
  private func prepareElement(size: CGSize, type: Element, attributes: UICollectionViewLayoutAttributes) {
    guard size != .zero else { return }
    
    attributes.frame = CGRect(origin: CGPoint(x: 0, y: contentHeight), size: size)
    contentHeight = attributes.frame.maxY
    
    cache[type]?[attributes.indexPath] = attributes
  }
}

//MARK: - PROVIDING ATTRIBUTES TO THE COLLECTIONVIEW
extension CustomLayout {
  
  public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    switch elementKind {
    case UICollectionElementKindSectionHeader:
      return cache[.sectionHeader]?[indexPath]
      
    case UICollectionElementKindSectionFooter:
      return cache[.sectionFooter]?[indexPath]
      
    default:
      return nil
    }
  }
  
  override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    return cache[.cell]?[indexPath]
  }
  
  override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    visibleLayoutAttributes.removeAll(keepingCapacity: true)

    for (_, elementInfos) in cache {
      for (_, attributes) in elementInfos {
        if attributes.frame.intersects(rect) {
          visibleLayoutAttributes.append(attributes)
        }
      }
    }
    return visibleLayoutAttributes
  }
}
