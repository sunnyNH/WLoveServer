//
//  RouteTool.swift
//  NHServer
//
//  Created by niuhui on 2017/7/27.
//
//

import Vapor
struct RouteTool {
    static func setUp() {
        ///sign业务
        SignController().registeredRouting()
        ///user业务
        UserController().registeredRouting()
        //验证码
        VerifyCodeController().registeredRouting()
        ///load业务
        LoadController().registeredRouting()
        ///around业务
        AroundController().registeredRouting()
        ///comment业务
        CommentController().registeredRouting()
        ///回复业务
        ReplyController().registeredRouting()
        ///notice业务
        NoticeController().registeredRouting()
        //好友业务
        FriendController().registeredRouting()
        //附近的人
        NearbyController().registeredRouting()
        //意见反馈
        FeedBackController().registeredRouting()
        //举报
        ReportController().registeredRouting()
        //v2 上传文件接口
        V2_LoadController().registeredRouting()
        //内部接口
        InnerController().registeredRouting()
    }
}
