//
//  Bond+Arrays.swift
//  Bond
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//






//  스위프트본드의 디자인/구현상 결함을 work around하기 위해서 급조된 패치.
//  지원될 것 같은 인터페이스가 제공되지만, 실제로는 제대로 작동하지 않고
//  정적 에러도 나지 않고 동적 에러도 나지 않는 기능들을 체크해서 확실하게 에러를
//  내도록 함.
//
//  여기에 들어간 패치는 업스트림으로 올리든지, 아니면 매번 재적용시켜줘야 함.
//
//  1.0 릴리즈후에는 본드를 갈아치우든지 해야지 -_-...
//
//  이상하게 동작했던 메서드들은 사실 모두 `internal`이었음...







import Foundation

// MARK: - Vector Dynamic

// MARK: Array Bond

public class ArrayBond<T>: Bond<Array<T>> {
  public var willInsertListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var didInsertListener: ((DynamicArray<T>, [Int]) -> Void)?
  
  public var willRemoveListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var didRemoveListener: ((DynamicArray<T>, [Int]) -> Void)?
  
  public var willUpdateListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var didUpdateListener: ((DynamicArray<T>, [Int]) -> Void)?

  
  override public init() {
    super.init()
  }
  
//  override public func bind(dynamic: Dynamic<Array<T>>) {
//    bind(dynamic, fire: true, strongly: true)
//  }
//  
//  override public func bind(dynamic: Dynamic<Array<T>>, fire: Bool) {
//    bind(dynamic, fire: fire, strongly: true)
//  }
  
    
//    @availability(*,unavailable)
    override public func bind(dynamic: Dynamic<Array<T>>, fire: Bool, strongly: Bool) {
//        fatalError("Do not use this method. Unexpected behavior is very likely to happen.")
        super.bind(dynamic, fire: fire, strongly: strongly)
    }
//    
//    public func bind(dynamic: DynamicArray<T>, fire: Bool, strongly: Bool) {
//        super.bind(dynamic, fire: fire, strongly: strongly)
//    }
}

// MARK: Dynamic array

public class DynamicArray<T>: Dynamic<Array<T>>, SequenceType {
  
  public typealias Element = T
  public typealias Generator = DynamicArrayGenerator<T>
  
  public override init(_ v: Array<T>) {
    super.init(v)
  }
  
  public override func bindTo(bond: Bond<Array<T>>) {
    bond.bind(self, fire: true, strongly: true)
  }
  
  public override func bindTo(bond: Bond<Array<T>>, fire: Bool) {
    bond.bind(self, fire: fire, strongly: true)
  }
  
  public override func bindTo(bond: Bond<Array<T>>, fire: Bool, strongly: Bool) {
    bond.bind(self, fire: fire, strongly: strongly)
  }
  
  public var count: Int {
    return value.count
  }
  
  public var capacity: Int {
    return value.capacity
  }
  
  public var isEmpty: Bool {
    return value.isEmpty
  }
  
  public var first: T? {
    return value.first
  }
  
  public var last: T? {
    return value.last
  }
  
  public func append(newElement: T) {
    dispatchWillInsert([value.count])
    value.append(newElement)
    dispatchDidInsert([value.count-1])
  }
  
  public func append(array: Array<T>) {
    if array.count > 0 {
      let count = value.count
      dispatchWillInsert(Array(count..<value.count))
      value += array
      dispatchDidInsert(Array(count..<value.count))
    }
  }
  
  public func removeLast() -> T {
    if self.count > 0 {
      dispatchWillRemove([value.count-1])
      let last = value.removeLast()
      dispatchDidRemove([value.count])
      return last
    }
    
    fatalError("Cannot remveLast() as there are no elements in the array!")
  }
  
  public func insert(newElement: T, atIndex i: Int) {
    dispatchWillInsert([i])
    value.insert(newElement, atIndex: i)
    dispatchDidInsert([i])
  }
  
  public func splice(array: Array<T>, atIndex i: Int) {
    if array.count > 0 {
      dispatchWillInsert(Array(i..<i+array.count))
      value.insertContentsOf(array, at: i)
      dispatchDidInsert(Array(i..<i+array.count))
    }
  }
  
  public func removeAtIndex(index: Int) -> T {
    dispatchWillRemove([index])
    let object = value.removeAtIndex(index)
    dispatchDidRemove([index])
    return object
  }
  
  public func removeAll(keepCapacity: Bool) {
    let count = value.count
    dispatchWillRemove(Array<Int>(0..<count))
    value.removeAll(keepCapacity: keepCapacity)
    dispatchDidRemove(Array<Int>(0..<count))
  }
  
  public subscript(index: Int) -> T {
    get {
      return value[index]
    }
    set(newObject) {
      if index == value.count {
        dispatchWillInsert([index])
        value[index] = newObject
        dispatchDidInsert([index])
      } else {
        dispatchWillUpdate([index])
        value[index] = newObject
        dispatchDidUpdate([index])
      }
    }
  }
  
  public func generate() -> DynamicArrayGenerator<T> {
    return DynamicArrayGenerator<T>(array: self)
  }
  
  private func dispatchWillInsert(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willInsertListener?(self, indices)
      }
    }
  }
  
  private func dispatchDidInsert(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didInsertListener?(self, indices)
      }
    }
  }
  
  private func dispatchWillRemove(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willRemoveListener?(self, indices)
      }
    }
  }

  private func dispatchDidRemove(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didRemoveListener?(self, indices)
      }
    }
  }
  
  private func dispatchWillUpdate(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willUpdateListener?(self, indices)
      }
    }
  }
  
  private func dispatchDidUpdate(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didUpdateListener?(self, indices)
      }
    }
  }
}

public struct DynamicArrayGenerator<T>: GeneratorType {
  private var index = -1
  private let array: DynamicArray<T>
  
  init(array: DynamicArray<T>) {
    self.array = array
  }
  
  public typealias Element = T
  
  public mutating func next() -> T? {
    index++
    return index < array.count ? array[index] : nil
  }
}

// MARK: Dynamic Array Map Proxy

/// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
public class DynamicArrayMapProxy<T, U>: DynamicArray<U> {
  private unowned var sourceArray: DynamicArray<T>
  private var mapf: (T, Int) -> U
  private let bond: ArrayBond<T>
  
  private init(sourceArray: DynamicArray<T>, mapf: (T, Int) -> U) {
    self.sourceArray = sourceArray
    self.mapf = mapf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    super.init([])
    
    bond.willInsertListener = { [unowned self] array, i in
      self.dispatchWillInsert(i)
    }
    
    bond.didInsertListener = { [unowned self] array, i in
      self.dispatchDidInsert(i)
    }
    
    bond.willRemoveListener = { [unowned self] array, i in
      self.dispatchWillRemove(i)
    }
    
    bond.didRemoveListener = { [unowned self] array, i in
      self.dispatchDidRemove(i)
    }
    
    bond.willUpdateListener = { [unowned self] array, i in
      self.dispatchWillUpdate(i)
    }
    
    bond.didUpdateListener = { [unowned self] array, i in
      self.dispatchDidUpdate(i)
    }
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var count: Int {
    return sourceArray.count
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var capacity: Int {
    return sourceArray.capacity
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var isEmpty: Bool {
    return sourceArray.isEmpty
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var first: U? {
    if let first = sourceArray.first {
      return mapf(first, 0)
    } else {
      return nil
    }
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var last: U? {
    if let last = sourceArray.last {
      return mapf(last, sourceArray.count - 1)
    } else {
      return nil
    }
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override func append(newElement: U) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override func append(array: Array<U>) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override func removeLast() -> U {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override func insert(newElement: U, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override func splice(array: Array<U>, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override func removeAtIndex(index: Int) -> U {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override func removeAll(keepCapacity: Bool) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override subscript(index: Int) -> U {
    get {
        return mapf(sourceArray[index], index)
    }
    set(newObject) {
      fatalError("Modifying proxy array is not supported!")
    }
  }
}

func indexOfFirstEqualOrLargerThan(x: Int, array: [Int]) -> Int {
  var idx: Int = -1
  for (index, element) in array.enumerate() {
    if element < x {
      idx = index
    } else {
      break
    }
  }
  return idx + 1
}

// MARK: Dynamic Array Filter Proxy

/// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
public class DynamicArrayFilterProxy<T>: DynamicArray<T> {
  private unowned var sourceArray: DynamicArray<T>
  private var pointers: [Int] = []
  private var filterf: T -> Bool
  private let bond: ArrayBond<T>
  
  private init(sourceArray: DynamicArray<T>, filterf: T -> Bool) {
    self.sourceArray = sourceArray
    self.filterf = filterf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    
    super.init([])
    
    for (index, element) in sourceArray.enumerate() {
      if filterf(element) {
        pointers.append(index)
      }
    }
    
    bond.didInsertListener = { [unowned self] array, indices in
      var insertedIndices: [Int] = []
      var pointers = self.pointers
      
      for idx in indices {

        for (index, element) in pointers.enumerate() {
          if element >= idx {
            pointers[index] = element + 1
          }
        }
        
        let element = array[idx]
        if filterf(element) {
          let position = indexOfFirstEqualOrLargerThan(idx, array: pointers)
          pointers.insert(idx, atIndex: position)
          insertedIndices.append(position)
        }
      }
      
      if insertedIndices.count > 0 {
       self.dispatchWillInsert(insertedIndices)
      }
      
      self.pointers = pointers
      
      if insertedIndices.count > 0 {
        self.dispatchDidInsert(insertedIndices)
      }
    }
    
    bond.willRemoveListener = { [unowned self] array, indices in
      var removedIndices: [Int] = []
      var pointers = self.pointers
      
      for idx in Array(indices.reverse()) {
        
        if let idx = pointers.indexOf(idx) {
          pointers.removeAtIndex(idx)
          removedIndices.append(idx)
        }
        
        for (index, element) in pointers.enumerate() {
          if element >= idx {
            pointers[index] = element - 1
          }
        }
      }
      
      if removedIndices.count > 0 {
        self.dispatchWillRemove(Array(removedIndices.reverse()))
      }
      
      self.pointers = pointers
      
      if removedIndices.count > 0 {
        self.dispatchDidRemove(Array(removedIndices.reverse()))
      }
    }
    
    bond.didUpdateListener = { [unowned self] array, indices in
      
      let idx = indices[0]
      let element = array[idx]

      var insertedIndices: [Int] = []
      var removedIndices: [Int] = []
      var updatedIndices: [Int] = []
      var pointers = self.pointers
      
      if let idx = pointers.indexOf(idx) {
        if filterf(element) {
          // update
          updatedIndices.append(idx)
        } else {
          // remove
          pointers.removeAtIndex(idx)
          removedIndices.append(idx)
        }
      } else {
        if filterf(element) {
          let position = indexOfFirstEqualOrLargerThan(idx, array: pointers)
          pointers.insert(idx, atIndex: position)
          insertedIndices.append(position)
        } else {
          // nothing
        }
      }

      if insertedIndices.count > 0 {
        self.dispatchWillInsert(insertedIndices)
      }
      
      if removedIndices.count > 0 {
        self.dispatchWillRemove(removedIndices)
      }
      
      if updatedIndices.count > 0 {
        self.dispatchWillUpdate(updatedIndices)
      }
      
      self.pointers = pointers
      
      if updatedIndices.count > 0 {
        self.dispatchDidUpdate(updatedIndices)
      }
      
      if removedIndices.count > 0 {
        self.dispatchDidRemove(removedIndices)
      }
      
      if insertedIndices.count > 0 {
        self.dispatchDidInsert(insertedIndices)
      }
    }
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
    //  컴파일러 버그 때문에 참조 포인트가 리포트가 되지 않으므로 무용지물.
    //  그냥 다이나믹으로 추적할것.
//    @availability(*,unavailable)
public override var value: [T] {
    get {
        fatalError("Do not use this property. This property does not work.")
    }
    set {
        fatalError("Do not use this property. This property does not work.")
    }
}
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var count: Int {
    return pointers.count
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var capacity: Int {
    return pointers.capacity
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var isEmpty: Bool {
    return pointers.isEmpty
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var first: T? {
    if let first = pointers.first {
      return sourceArray[first]
    } else {
      return nil
    }
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override var last: T? {
    if let last = pointers.last {
      return sourceArray[last]
    } else {
      return nil
    }
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
    @available(*,unavailable)
  public override func append(newElement: T) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
    @available(*,unavailable)
  public override func append(array: Array<T>) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
    @available(*,unavailable)
  public override func removeLast() -> T {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
    @available(*,unavailable)
  public override func insert(newElement: T, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
    @available(*,unavailable)
  public override func splice(array: Array<T>, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
    @available(*,unavailable)
  public override func removeAtIndex(index: Int) -> T {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
    @available(*,unavailable)
  public override func removeAll(keepCapacity: Bool) {
    fatalError("Modifying proxy array is not supported!")
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public override subscript(index: Int) -> T {
    get {
      return sourceArray[pointers[index]]
    }
    @available(*,unavailable)
    set {
      fatalError("Modifying proxy array is not supported!")
    }
  }
}

// MARK: Dynamic Array additions

extension DynamicArray
{
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public func map<U>(f: (T, Int) -> U) -> DynamicArrayMapProxy<T, U> {
    return _map(self, f: f)
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public func map<U>(f: T -> U) -> DynamicArrayMapProxy<T, U> {
    let mapf = { (o: T, i: Int) -> U in f(o) }
    return _map(self, f: mapf)
  }
    
    /// **주의** 원래는 `public`이 아니고 `internal`이었음. 즉, 비공개 API였음.
  public func filter(f: T -> Bool) -> DynamicArrayFilterProxy<T> {
    return _filter(self, f: f)
  }
}

// MARK: Map

private func _map<T, U>(dynamicArray: DynamicArray<T>, f: (T, Int) -> U) -> DynamicArrayMapProxy<T, U> {
  return DynamicArrayMapProxy(sourceArray: dynamicArray, mapf: f)
}

// MARK: Filter

private func _filter<T>(dynamicArray: DynamicArray<T>, f: T -> Bool) -> DynamicArrayFilterProxy<T> {
  return DynamicArrayFilterProxy(sourceArray: dynamicArray, filterf: f)
}
