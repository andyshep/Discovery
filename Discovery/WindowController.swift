//
//  WindowController.swift
//  Discovery
//
//  Created by Andrew Shepard on 3/1/20.
//  Copyright © 2020 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

class WindowController: NSWindowController {
    
    @IBOutlet private weak var reloadButton: NSButton!
    @IBOutlet private weak var broadcastButton: NSButton!
    
    private var cancellables: [AnyCancellable] = []
    
    private lazy var ssdpManager: SSDPManager = {
        guard let manager = SSDPManager() else { fatalError() }
        return manager
    }()
    
    lazy private var listViewController: ListViewController = {
        guard let splitViewController = contentViewController as? NSSplitViewController else { fatalError() }
        guard let viewController = splitViewController.children[0] as? ListViewController else { fatalError() }
        return viewController
    }()
    
    lazy private var detailViewController: DetailViewController = {
        guard let splitViewController = contentViewController as? NSSplitViewController else { fatalError() }
        guard let viewController = splitViewController.children[1] as? DetailViewController else { fatalError() }
        return viewController
    }()
    
    lazy private var servicesArrayController: NSArrayController = listViewController.servicesArrayController

    override func windowDidLoad() {
        super.windowDidLoad()
    
        window?.titleVisibility = .hidden
        
        servicesArrayController
            .selectionIndexPublisher
            .compactMap { [weak self] _ -> SSDPServiceWrapper? in
                let selected = self?.servicesArrayController.selectedObjects
                return selected?.first as? SSDPServiceWrapper
            }
            .removeDuplicates()
            .sink { [weak self] service in
                self?.detailViewController.representedObject = service.payload
            }
            .store(in: &cancellables)
        
        broadcastButton
            .publisher
            .receive(subscriber: ssdpManager.broadcastEventTrigger)
        
        listViewController.representedObject = ssdpManager
    }

}
