import FluentProvider
import MySQLProvider
import RedisProvider
extension Config {
    public func setup() throws {
        Node.fuzzy = [Row.self, JSON.self, Node.self]
        
        try setupProviders()
        try setupPreparations()
    }
    private func setupProviders() throws {
        try addProvider(MySQLProvider.Provider.self)
        //如果用redis 这里打开
        try addProvider(RedisProvider.Provider.self)
    }
    private func setupPreparations() throws {
        preparations.append(User.self)
        preparations.append(Session.self)
        preparations.append(SMSIP.self)
        preparations.append(VerifyCode.self)
        
        preparations.append(AroundMsg.self)
        preparations.append(AroundMsgUp.self)
        preparations.append(AroundComUp.self)
        preparations.append(AroundNotice.self)
        preparations.append(AroundComment.self)
        preparations.append(CommentReply.self)
        preparations.append(ReportAround.self)
        preparations.append(ReportAroundUser.self)
        
        preparations.append(Friend.self)
        preparations.append(FriendNotice.self)
        preparations.append(FriendNoticeCount.self)
        preparations.append(Nearby.self)

        preparations.append(FeedBack.self)
        preparations.append(addAroundFileType.self)
        preparations.append(File.self)
    }
}
