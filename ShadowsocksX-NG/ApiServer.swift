//
//  ApiServer.swift
//  ShadowsocksX-R
//
//  Created by CYC on 2016/10/9.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation
import GCDWebServer



class ApiMgr{
    static let shard = ApiMgr()
    
    let apiserver = GCDWebServer()
    let SerMgr = ServerProfileManager.instance
    let defaults = NSUserDefaults.standardUserDefaults()
    let appdeleget = NSApplication.sharedApplication().delegate as! AppDelegate
    let api_port:UInt = 9528
    
    func start(){
        setRouter()
        do{
            try apiserver.startWithOptions([GCDWebServerOption_Port:api_port,"BindToLocalhost":true])
        }catch{
            NSLog("Error:ApiServ start fail")
        }
    }
    
    func setRouter(){
        apiserver.addHandlerForMethod("GET", path: "/servers", requestClass: GCDWebServerRequest.self, processBlock: {request in
            return GCDWebServerDataResponse(JSONObject: self.serverList())
        })
        
        apiserver.addHandlerForMethod("POST", path: "/toggle", requestClass: GCDWebServerRequest.self, processBlock: {request in
            self.toggle()
            return GCDWebServerDataResponse(JSONObject: ["Status":1])
        })
        
        apiserver.addHandlerForMethod("POST", path: "/mode", requestClass: GCDWebServerURLEncodedFormRequest.self, processBlock: {request in
            if let arg = ((request as! GCDWebServerURLEncodedFormRequest).arguments["value"])as? String
            {
                switch arg{
                case "auto":self.defaults.setValue("auto", forKey: "ShadowsocksRunningMode")
                case "global":self.defaults.setValue("global", forKey: "ShadowsocksRunningMode")
                case "manual":self.defaults.setValue("manual", forKey: "ShadowsocksRunningMode")
                case "bypasschina":self.defaults.setValue("bypasschina", forKey: "ShadowsocksRunningMode")
                default:return GCDWebServerDataResponse(JSONObject: ["Status":0])
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.appdeleget.updateRunningModeMenu()
                });
                return GCDWebServerDataResponse(JSONObject: ["Status":1])
            }
            return GCDWebServerDataResponse(JSONObject: ["Status":0])
        })
        
        apiserver.addHandlerForMethod("GET", path: "/mode", requestClass: GCDWebServerRequest.self, processBlock: {request in
            if let current = self.defaults.stringForKey("ShadowsocksRunningMode"){
                return GCDWebServerDataResponse(JSONObject: ["mode":current])
            }
            return GCDWebServerDataResponse(JSONObject: ["mode":"unknow"])
        })
        
        apiserver.addHandlerForMethod("GET", path: "/status", requestClass: GCDWebServerRequest.self, processBlock: {request in
            let current = self.defaults.boolForKey("ShadowsocksOn")
            return GCDWebServerDataResponse(JSONObject: ["enable":current])
        })
        
        apiserver.addHandlerForMethod("POST", path: "/servers", requestClass: GCDWebServerRequest.self, processBlock: {request in
            let uuid = ((request as! GCDWebServerURLEncodedFormRequest).arguments["uuid"])as? String
            if uuid == nil{return GCDWebServerDataResponse(JSONObject: ["status":0])}
            self.changeServ(uuid!)
            return GCDWebServerDataResponse(JSONObject: ["status":1])
        })
    }
    
    func serverList()->NSArray{
        var data = [[String:String]]()
        for each in self.SerMgr.profiles{
            data.append(["id":each.uuid,"note":each.remark])
        }
        return data
    }
    
    func toggle(){
        var isOn = self.defaults.boolForKey("ShadowsocksOn")
        isOn = !isOn
        self.defaults.setBool(isOn, forKey: "ShadowsocksOn")
        appdeleget.applyConfig()
        dispatch_async(dispatch_get_main_queue(), {
            self.appdeleget.updateMainMenu()
        });
    }
    
    func changeServ(uuid:String){
        for each in SerMgr.profiles{
            if each.uuid == uuid{
                SerMgr.setActiveProfiledId(uuid)
                appdeleget.updateServersMenu()
                SyncSSLocal()
                return
            }
        }
    }
}
