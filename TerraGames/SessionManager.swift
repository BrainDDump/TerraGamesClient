import Foundation
import MultipeerConnectivity

enum SessionManagerEventId: String {
    case NodeFound                  = "NodeFound"
    case RecievedInvitationFromNode = "RecievedInvitationFromNode"
    
    case NodeDidConnect    = "NodeDidConnect"
    case NodeDidDisconnect = "NodeDidDisconnect"
    
    case DidRecieveMessage = "DidRecieveDataFromNode"
}

protocol MCSessionManagerDelegate: class {
    func peerDidConnect(_ peerId: String)
    func peerDidDisconnect(_ peerId: String)
    
    func didRecieveDataFromPeer(_ peerId: String, data: Data)
    
    func foundPeer(_ peerId: String, discoveryInfo: [String: String]?)
    
    func recievedInvitationFromPeer(_ peerId: String, context: Data?)
}

extension MCSessionState {
    func stringValue() -> String {
        switch(self) {
        case .notConnected:
            return "NotConnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        }
    }
}

class MCSessionManager: NSObject {
    typealias InviteHandler = (Bool, MCSession) -> Void
    
    let debugEnabled: Bool
    
    weak var delegate: MCSessionManagerDelegate!
    
    let isHost: Bool
    
    fileprivate let session:           MCSession
    fileprivate let serviceAdvertiser: MCNearbyServiceAdvertiser
    fileprivate let serviceBrowser:    MCNearbyServiceBrowser
    
    fileprivate var inviteHandlers = [String: InviteHandler]()
    fileprivate var peersTable     = [String: MCPeerID]()
    
    init(serviceType: String, username: String, isHost: Bool, debugMode: Bool = false) {
        self.isHost = isHost
        
        debugEnabled = debugMode
        
        let myPeerId = MCPeerID(displayName: username)
        session = MCSession(peer: myPeerId)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser    = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        session.delegate           = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate    = self
        
        if isHost {
            if debugEnabled {
                print("*** DEBUG: ", "init; started browsing")
            }
            serviceBrowser.startBrowsingForPeers()
        } else {
            if debugEnabled {
                print("*** DEBUG: ", "init; started advertising")
            }
            serviceAdvertiser.startAdvertisingPeer()
        }
    }
}

extension MCSessionManager {
    // Managing invitations
    func inviteNodeWithId(_ id: String, context: Data?) {
        if debugEnabled {
            print("*** DEBUG: ", "SessionManager::inviteNodeWithId: ", id)
        }
        
        guard let peer = peersTable[id] else {
            print("SessionManager::inviteNodeWithId", id, "error: Not found in the table")
            return
        }
        
        serviceBrowser.invitePeer(peer, to: session, withContext: context, timeout: 10)
    }
    
    func handleInviteFromNode(withId id: String, accept: Bool) {
        if debugEnabled {
            print("*** DEBUG", "handleInviteFromNode:", id)
        }
        
        guard !isHost else {
            print("handleInviteFromNode", "error - local player is host, can not accept invites")
            return
        }
        
        guard let invitationHandler = inviteHandlers[id] else {
            print("acceptInviteFromNode", "error: invitationHandler not found")
            return
        }
        
        invitationHandler(accept, session)
    }
    
    // Interaction with nodes
    func broadcast(_ data: Data) {
        sendDataToNodes(data, nodeIds: session.connectedPeers.map({ $0.displayName }))
    }
    
    func sendDataToNode(_ data: Data, nodeId: String) {
        if debugEnabled {
            print("*** DEBUG: ", "sendDataToNode ", "to node: ", nodeId)
        }
        
        let sessionPeerIds = session.connectedPeers.map({ $0.displayName })
        guard sessionPeerIds.index(of: nodeId) != nil else {
            print("sendDataToNode id:", nodeId, "error: not connected to session")
            return
        }
        
        guard let peerIdObj = peersTable[nodeId] else {
            print("sendDataToNode id:", nodeId, "error: peer not found in peers table")
            return
        }
        
        do {
            try session.send(data, toPeers: [peerIdObj], with: MCSessionSendDataMode.unreliable)
        } catch let error {
            print("Send data error", error)
        }
    }
    
    func sendDataToNodes(_ data: Data, nodeIds: [String]) {
        if debugEnabled {
            print("*** DEBUG: ", "sendDataToNodes ", "nodeIds: ", nodeIds)
        }
        
        let sessionPeerIds = session.connectedPeers.map({ $0.displayName })
        var recipientsPeerIds = [MCPeerID]()
        for nodeId in nodeIds {
            guard sessionPeerIds.index(of: nodeId) != nil else {
                print("nodeId:", nodeId, "error: peer not currently connected to session")
                continue
            }
            
            guard let peerId = peersTable[nodeId] else {
                print("nodeId:", nodeId, "error: peer not found in peersTable")
                continue
            }
            
            recipientsPeerIds.append(peerId)
        }
        
        do {
            try session.send(data, toPeers: recipientsPeerIds, with: MCSessionSendDataMode.reliable)
        } catch let error {
            print("Send data error", error)
        }
    }
}

extension MCSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if debugEnabled {
            print("*** DEBUG: ", "session::peer: ", peerID, "didChangeState for state:", state.stringValue())
        }
        
        peersTable[peerID.displayName] = peerID
        
        switch state {
        case .connected:
            delegate.peerDidConnect(peerID.displayName)
        case .notConnected:
            delegate.peerDidDisconnect(peerID.displayName)
        case .connecting:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if debugEnabled {
            print("*** DEBUG: ", "session::didReceiveData ", "fromPeer: ", peerID)
        }
        
        delegate.didRecieveDataFromPeer(peerID.displayName, data: data)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError()
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError()
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        fatalError()
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}

extension MCSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if debugEnabled {
            print("*** DEBUG", "browser::foundPeer: ", peerID, "discoveryInfo: ", info)
        }
        
        guard isHost else {
            print("browser::didReceiveInvitationFromPeer", "error - local player is not a host, can not browse")
            return
        }
        
        peersTable[peerID.displayName] = peerID
        
        delegate.foundPeer(peerID.displayName, discoveryInfo: info)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if debugEnabled {
            print("*** DEBUG", "browser::lostPeer: ", peerID)
        }
    }
}

extension MCSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if debugEnabled {
            print("*** DEBUG", "advertiser::didReceiveInvitationFromPeer", peerID, "with context: ", context)
        }
        
        guard !isHost else {
            print("advertiser::didReceiveInvitationFromPeer", "error - local player is host, can not accept invites")
            return
        }
        
        peersTable[peerID.displayName] = peerID
        inviteHandlers[peerID.displayName] = invitationHandler
        
        delegate.recievedInvitationFromPeer(peerID.displayName, context: context)
    }
    
}
