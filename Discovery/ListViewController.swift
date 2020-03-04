//
//  ListViewController.swift
//  Discovery
//
//  Created by Andrew Shepard on 3/1/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

class ListViewController: NSViewController {
    
    @IBOutlet private weak var tableView: NSTableView!
    
    @objc private var services: [SSDPServiceWrapper] = []
    
    private let ssdpManager = SSDPManager()
    private var cancellables: [AnyCancellable] = []
    
    lazy var servicesArrayController: NSArrayController = {
        let controller = NSArrayController()
        controller.bind(.contentArray, to: self, withKeyPath: "services")
//        controller.preservesSelection = true
//        controller.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.bind(.content, to: servicesArrayController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: servicesArrayController, withKeyPath: "selectionIndexes")
        
        bind(to: ssdpManager)
        
        ssdpManager?.startListening()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

private extension ListViewController {
    private func bind(to ssdpManager: SSDPManager?) {
        ssdpManager?.listenerSocketSubject
            .sink(receiveValue: { [weak self] (result) in
                guard let this = self else { return }
                
                switch result {
                case .success(let data):
                    guard let service = SSDPServiceParser.parse(data) else {
                        return print("could not create service from \(data.count) bytes of data")
                    }
                    
                    guard let payload = String(data: data, encoding: .utf8) else {
                        return print("could not decode utf8 data from \(data.count) bytes of data")
                    }
                    
                    let wrapper = SSDPServiceWrapper(service: service, payload: payload)
                    
                    if !this.services.contains(wrapper) {
                        this.willChangeValue(for: \.services)
                        this.services.append(wrapper)
                        this.didChangeValue(for: \.services)
                    }
                    
                    print("\(wrapper)")
                    print("success!")
                    
                case .failure(let error):
                    print("error: \(error)")
                }
            })
            .store(in: &cancellables)
    }
}

internal class SSDPServiceWrapper: NSObject {
    let underlying: SSDPService
    let payload: String
    
    @objc var displayName: String {
        // FIXME
        let elements = underlying.uniqueServiceName.split(separator: ":")
        return String(elements[1])
    }
    
    required init(service: SSDPService, payload: String) {
        self.underlying = service
        self.payload = payload
        
        super.init()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let service = object as? SSDPServiceWrapper else { return false }
        
        let uniqueServiceName = service.underlying.uniqueServiceName
        return underlying.uniqueServiceName.elementsEqual(uniqueServiceName)
    }
}
