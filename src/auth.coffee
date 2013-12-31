mongo = require('mongodb')
config = require('./config')
Invisible = require('./invisible')
crypto = require('crypto')

col = undefined
mongo.connect config.db_uri, (err, database) ->
    throw err if err?
    col = database.collection('AuthToken')


generateToken = (user, cb) ->
    ### Takes a user model a generates a new access_token for it. ###

    crypto.randomBytes 48, (ex, buf)->
        token = buf.toString('hex')
        
        crypto.randomBytes 48, (ex, buf)->
            refresh = buf.toString('hex')
            
            #TODO set expire via config
            t = new Date()
            t.setSeconds(t.getSeconds() + 86410)

            data = 
                token: token
                user: user._id
                refresh: refresh
                expires: t

            col.save data, (err, result)->
                cb(err) if err
                cb null, 
                    token_type: "bearer"
                    acces_token: token
                    refresh_token: refresh
                    expires_in: 86400


getToken = (req, res) ->
    ### 
    Controller that generates and saves the access_token, either based on the
    client credentials or a previously generated refresh token.
    ###

    if req.body.grant_type == 'password' 
        #User authenticates
        username = req.body.username
        password = req.body.password
        if !username or !password
            return res.send(401)
        
        config.authenticate username, password, (err, user) ->
            if err or not user
                return res.send(401)
            generateToken user, (err, token)->
                if not err
                    return res.send(200, token)
                return res.send(401)

    else if req.body.grant_type == 'refresh_token'
        #Token is refreshed
        #TODO get user from refresh_token, call generate
        return
    return res.send(401)


module.exports = (req, res, next) ->
    ### 
    Auth middleware. If authentication is configured, exposes a "authtoken"
    url to generate an access_token following OAuth2's password grant.
    All other endpoints will require the token in the Authorization header.
    ###

    if not config.authenticate
        return next()

    if req.path.indexOf('/invisible/authtoken/') == 0
        # exchange credentials per token
        return createToken(req, res)

    header = req.header('Authorization')
    if not header or not header.indexOf("Bearer ") == 0
        return res.send(401)
    token = header.split(" ")[1]
    
    col.findOne {token: token}, (err, token) ->
        if err
            return res.send(401)

        #FIXME check that it's not expired
        
        Invisible[config.userModel or 'User'].findById token.user.toString(), (err, user)->
            if err
                return res.send(401)

            req.user = user
            next()