_ = require("underscore")
Invisible = require('./invisible')

module.exports = (app) ->
	app.get("/invisible/:modelName", query)
	app.post("/invisible/:modelName", save)
	app.get("/invisible/:modelName/:id", show)
	app.put("/invisible/:modelName/:id", update)
	app.delete("/invisible/:modelName/:id", remove)

#rest controllers
query = (req, res) -> 
    #TODO error handling
    if req.query.query?
        criteria = JSON.parse(req.query.query)
    else
        criteria = {}

    Model = Invisible[req.params.modelName]
    Model.query criteria, (results) ->
        res.send(results)

save = (req, res) ->
    Model = Invisible[req.params.modelName]
    instance = new Model()
    _.extend(instance, req.body)
    instance.save (instance) ->
        res.send(200, instance)

show = (req, res) ->
    #TODO error handling
    Model = Invisible[req.params.modelName]
    
    Model.findById req.params.id, (result) ->
        if result?
            obj = JSON.parse(JSON.stringify(result))
            res.send(200, obj)
        else
            res.send(404)

update = (req, res) ->
    Model = Invisible[req.params.modelName]
    
    Model.findById req.params.id, (instance) ->
        if instance?
            _.extend(instance, req.body)
            instance.save (instance) ->
                res.send(200, instance)
        else
            res.send(404)

remove = (req, res) ->
    Model = Invisible[req.params.modelName]

    Model.findById req.params.id, (instance) ->
        if instance?
            instance.delete (result) ->
                res.send(200)
        else
            res.send(404)
